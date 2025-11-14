CREATE OR REPLACE FUNCTION public.unequip_item(
    p_user_id uuid,
    p_item_id_to_unequip uuid
)
RETURNS text -- 回傳一個狀態碼
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet_id uuid;
BEGIN
    -- 獲取用戶的寵物 ID
    SELECT id INTO v_pet_id
    FROM public.pets
    WHERE user_id = p_user_id
    LIMIT 1;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'Pet not found for user';
    END IF;

    -- 脫下指定的寵物裝備
    UPDATE public.pets
    SET
        equipped_top_id = CASE
            WHEN equipped_top_id = p_item_id_to_unequip THEN NULL
            ELSE equipped_top_id
        END,
        
        equipped_pants_id = CASE
            WHEN equipped_pants_id = p_item_id_to_unequip THEN NULL
            ELSE equipped_pants_id
        END,
        
        equipped_shoes_id = CASE
            WHEN equipped_shoes_id = p_item_id_to_unequip THEN NULL
            ELSE equipped_shoes_id
        END,

        equipped_accessory_id = CASE
            WHEN equipped_accessory_id = p_item_id_to_unequip THEN NULL
            ELSE equipped_accessory_id
        END,

        updated_at = NOW()

    WHERE id = v_pet_id;

    RETURN 'unequip_successful';

EXCEPTION
    -- 捕捉任何意外錯誤
    WHEN OTHERS THEN
        RAISE WARNING 'Unequip item transaction failed: %', SQLERRM;
        RETURN 'unequip_failed_unexpectedly';

END;
$$;