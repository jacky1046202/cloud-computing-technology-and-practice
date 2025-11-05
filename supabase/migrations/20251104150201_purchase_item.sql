CREATE OR REPLACE FUNCTION public.purchase_item(
    p_user_id uuid,
    p_store_item_id uuid -- public.store_items 的 ID
)
RETURNS text -- 回傳一個狀態碼 (e.g., 'purchase_successful')
LANGUAGE plpgsql
SECURITY DEFINER 
AS $$
DECLARE
    v_item_price money;
    v_item_ref_id uuid;     -- 物品的 "真實" ID (來自 store_items.ref_id)
    v_item_stock int4;
    v_user_points money;
BEGIN
    -- 1. 獲取用戶的點數 (假設在 internal.accounts 中)
    SELECT points INTO v_user_points
    FROM internal.accounts
    WHERE user_id = p_user_id
    LIMIT 1;

    IF v_user_points IS NULL THEN
        RAISE EXCEPTION 'User account not found';
    END IF;

    -- 2. 獲取物品的價格、真實ID (ref_id) 和庫存
    SELECT price, ref_id, stock INTO v_item_price, v_item_ref_id, v_item_stock
    FROM public.store_items
    WHERE id = p_store_item_id
    LIMIT 1;

    IF v_item_price IS NULL THEN
        RAISE EXCEPTION 'Store item not found';
    END IF;

    -- 3. 檢查庫存
    IF v_item_stock <= 0 THEN
        RETURN 'item_out_of_stock'; -- 回傳錯誤：已售完
    END IF;

    -- 4. 檢查用戶是否已擁有 (用 ref_id 檢查 storage_items)
    IF EXISTS (
        SELECT 1 
        FROM public.storage_items si
        WHERE si.owner_id = p_user_id AND si.item_id = v_item_ref_id
    ) THEN
        RETURN 'item_already_owned'; -- 回傳錯誤：已擁有
    END IF;

    -- 5. 檢查點數是否足夠
    IF v_user_points < v_item_price THEN
        RETURN 'insufficient_funds'; -- 回傳錯誤：點數不足
    END IF;

    -- 6. 所有檢查通過，執行交易

    -- a. 扣除點數
    UPDATE internal.accounts
    SET points = points - v_item_price
    WHERE user_id = p_user_id;

    -- b. 將物品新增到用戶的 "倉庫" (storage_items)
    INSERT INTO public.storage_items (id, owner_id, owner_type, item_type, item_id, quantity)
    VALUES (
        gen_random_uuid(),
        p_user_id,
        'User',
        'Clothes',
        v_item_ref_id,
        1
    );

    -- c. 減少庫存
    UPDATE public.store_items
    SET stock = stock - 1
    WHERE id = p_store_item_id;

    -- 7. 回傳成功
    RETURN 'purchase_successful';

EXCEPTION
    -- 捕捉任何意外錯誤
    WHEN OTHERS THEN
        RAISE WARNING 'Purchase transaction failed: %', SQLERRM;
        RETURN 'purchase_failed_unexpectedly';
END;
$$;


GRANT EXECUTE ON FUNCTION public.purchase_item(uuid, uuid) TO authenticated;
