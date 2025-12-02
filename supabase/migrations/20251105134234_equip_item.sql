CREATE OR REPLACE FUNCTION public.equip_item(
    p_user_id uuid,
    p_item_id_to_equip uuid
)
RETURNS text -- 回傳狀態碼
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet_record public.pets;
    v_item_category e.item_category;
BEGIN
    -- 1. 獲取寵物資料 (包含 HP)
    SELECT * INTO v_pet_record
    FROM public.pets
    WHERE user_id = p_user_id
    LIMIT 1;

    IF v_pet_record IS NULL THEN
        RETURN 'pet_not_found';
    END IF;

    -- [!!] 2. 新增檢查：如果 HP < 60 (過重)，禁止裝備
    IF v_pet_record.hp < 30 THEN
        RETURN 'pet_is_overweight'; -- 回傳特殊錯誤碼
    END IF;

    -- 3. 獲取物品分類
    SELECT category_name INTO v_item_category
    FROM internal.clothes
    WHERE id = p_item_id_to_equip;

    IF v_item_category IS NULL THEN
        RETURN 'item_not_found';
    END IF;

    -- 4. 執行裝備更新 (根據分類更新對應欄位)
    UPDATE public.pets
    SET
        equipped_top_id = CASE WHEN v_item_category = 'Top' THEN p_item_id_to_equip ELSE equipped_top_id END,
        equipped_pants_id = CASE WHEN v_item_category = 'Pants' THEN p_item_id_to_equip ELSE equipped_pants_id END,
        equipped_shoes_id = CASE WHEN v_item_category = 'Shoes' THEN p_item_id_to_equip ELSE equipped_shoes_id END,
        equipped_accessory_id = CASE WHEN v_item_category = 'Accessory' THEN p_item_id_to_equip ELSE equipped_accessory_id END,
        updated_at = NOW()
    WHERE id = v_pet_record.id;

    RETURN 'equip_successful';
END;
$$;