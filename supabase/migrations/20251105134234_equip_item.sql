/**
 * 裝備一件物品到寵物身上
 * * 假設:
 * 1. internal.clothes 表有 "category_name" (e.item_category) 欄位
 * 2. public.pets 表有 "equipped_top_id" (uuid) ...等欄位
 * 3. public.storage_items 表的 "owner_id" 和 "item_id" 都是 uuid
 */
CREATE OR REPLACE FUNCTION public.equip_item(
    p_user_id uuid,
    p_item_id_to_equip uuid -- 這是 "internal.clothes" 的 ID
)
RETURNS text -- 回傳一個狀態碼
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet_id uuid;
    v_category e.item_category;
BEGIN
    -- 驗證用戶是否真的擁有這件物品
    -- (檢查 storage_items 表)
    IF NOT EXISTS (
        SELECT 1 
        FROM public.storage_items si
        WHERE si.owner_id = p_user_id AND si.item_id = p_item_id_to_equip
    ) THEN
        RAISE EXCEPTION 'Item not owned by user';
    END IF;

    -- 獲取該物品的分類(category)
    SELECT category_name INTO v_category
    FROM internal.clothes
    WHERE id = p_item_id_to_equip
    LIMIT 1;

    IF v_category IS NULL THEN
        RAISE EXCEPTION 'Item category not found';
    END IF;

    -- 獲取用戶的寵物 ID
    SELECT id INTO v_pet_id
    FROM public.pets
    WHERE user_id = p_user_id
    LIMIT 1;
    
    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Pet not found for user';
    END IF;

    -- 根據分類 (v_category) 動態更新 "pets" 表上正確的欄位
    UPDATE public.pets
    SET 
        -- 如果 v_category 是 'top'，則更新 equipped_top_id，否則保持原樣
        equipped_top_id = CASE 
            WHEN v_category = 'Top' THEN p_item_id_to_equip 
            ELSE equipped_top_id 
        END,

        -- 如果 v_category 是 'Pants'，則更新 equipped_pants_id，否則保持原樣
        equipped_pants_id = CASE 
            WHEN v_category = 'Pants' THEN p_item_id_to_equip 
            ELSE equipped_pants_id 
        END,

        -- 如果 v_category 是 'Shoes'，則更新 equipped_shoes_id，否則保持原樣
        equipped_shoes_id = CASE 
            WHEN v_category = 'Shoes' THEN p_item_id_to_equip 
            ELSE equipped_shoes_id 
        END,

        -- 如果 v_category 是 'Accessory'，則更新 equipped_accessory_id，否則保持原樣
        equipped_accessory_id = CASE 
            WHEN v_category = 'Accessory' THEN p_item_id_to_equip 
            ELSE equipped_accessory_id 
        END,
        
        updated_at = NOW()
        
    WHERE 
        id = v_pet_id; -- 只更新這隻寵物

    -- 5. 回傳成功
    RETURN 'equip_successful';

EXCEPTION
    -- 捕捉任何意外錯誤
    WHEN OTHERS THEN
        RAISE WARNING 'Equip item transaction failed: %', SQLERRM;
        RETURN 'equip_failed_unexpectedly';
END;
$$;


GRANT EXECUTE ON FUNCTION public.equip_item(uuid, uuid) TO authenticated;