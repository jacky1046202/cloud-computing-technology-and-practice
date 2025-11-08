/**
 * 獲取寵物外觀 (所有裝備的 "完整" 圖片 URL)。
 */
CREATE OR REPLACE FUNCTION public.get_pet_appearance(
    p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet_record public.pets;
    v_base_body_url text;
    
    v_default_empty_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Item/wore/transparent.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJJdGVtL3dvcmUvdHJhbnNwYXJlbnQucG5nIiwiaWF0IjoxNzYyNjEzNDU0LCJleHAiOjQ5MTYyMTM0NTR9.D-qFD78mN0Dk9cWz1tFL7vHGlU0piiMhSxp6V_5Az9I';
    
    v_dog_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTE2LCJleHAiOjQ5MTYyMTM1MTZ9.pdIHeHdcx25TdtPyYnq0qdem4WgIWjNnZyRjmiL7adw';
    
    v_cat_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTM3LCJleHAiOjQ5MTYyMTM1Mzd9.h8yNWt0gGJi5rAFqeubRe_WZEcEoD_7lVGKY2coX48E';
BEGIN
    -- 1. 獲取寵物
    SELECT * INTO v_pet_record
    FROM public.pets p
    WHERE p.user_id = p_user_id
    LIMIT 1;

    IF v_pet_record IS NULL THEN
        RAISE EXCEPTION 'Pet not found for user %', p_user_id;
    END IF;

    -- 2. 決定基礎身體 URL
    IF v_pet_record.species = 'Dog' THEN
        v_base_body_url := v_dog_body_url;
    ELSE
        v_base_body_url := v_cat_body_url;
    END IF;

    -- 3. 查詢所有裝備的圖片 URL
    RETURN (
        SELECT jsonb_build_object(
            'base_body', v_base_body_url,
            'top', COALESCE(top.item_url, v_default_empty_url),
            'pants', COALESCE(pants.item_url, v_default_empty_url),
            'shoes', COALESCE(shoes.item_url, v_default_empty_url),
            'accessory', COALESCE(acc.item_url, v_default_empty_url)
        )
        FROM (SELECT 1) AS dummy
        LEFT JOIN internal.clothes AS top ON top.id = v_pet_record.equipped_top_id
        LEFT JOIN internal.clothes AS pants ON pants.id = v_pet_record.equipped_pants_id
        LEFT JOIN internal.clothes AS shoes ON shoes.id = v_pet_record.equipped_shoes_id
        LEFT JOIN internal.clothes AS acc ON acc.id = v_pet_record.equipped_accessory_id
    );
END;
$$;