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
    v_superhappyface text;
    v_happyface text;
    v_normalface text;
    v_sadface text;
    v_final_face_url text;
    v_status_text text;
    
    v_default_empty_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Item/wore/transparent.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJJdGVtL3dvcmUvdHJhbnNwYXJlbnQucG5nIiwiaWF0IjoxNzYyNjEzNDU0LCJleHAiOjQ5MTYyMTM0NTR9.D-qFD78mN0Dk9cWz1tFL7vHGlU0piiMhSxp6V_5Az9I';
    
    v_dog_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTE2LCJleHAiOjQ5MTYyMTM1MTZ9.pdIHeHdcx25TdtPyYnq0qdem4WgIWjNnZyRjmiL7adw';
    v_dog_superhappyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_superhappyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX3N1cGVyaGFwcHlmYWNlLnBuZyIsImlhdCI6MTc2MzEyNzE5NiwiZXhwIjo0OTE2NzI3MTk2fQ.oxRkKPOjElanVQUUfaJPpUbYKxE65TZ28f_ExFlDSV8';
    v_dog_happyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_happyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2hhcHB5ZmFjZS5wbmciLCJpYXQiOjE3NjMxMjcxODEsImV4cCI6NDkxNjcyNzE4MX0.QKrZiM4-Zj2zY0sabQuDzMNYR1geEslK796OT8iHqiQ';
    v_dog_normalface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_normalface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX25vcm1hbGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MjExLCJleHAiOjY0OTM1MjcyMTF9.Xj9O3hLTWakCNUcvNcaGq-VCSgZnJWyonMDtCaxcQaA';
    v_dog_sadface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_sadface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX3NhZGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MjMwLCJleHAiOjcwOTI3MTEyMzB9.cCFm6w7hLsLnVs51t4vNZeoDyiPCbUIayFc2xc0pGe8';

    v_cat_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTM3LCJleHAiOjQ5MTYyMTM1Mzd9.h8yNWt0gGJi5rAFqeubRe_WZEcEoD_7lVGKY2coX48E';
    v_cat_superhappyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_superhappyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X3N1cGVyaGFwcHlmYWNlLnBuZyIsImlhdCI6MTc2MzEyNzA1MCwiZXhwIjo4MDcwMzI3MDUwfQ.mY4HZQ5WSYFfVppC7Zuq8K6oinKCKK5bRhzgLbdjWSQ';
    v_cat_happyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_happyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2hhcHB5ZmFjZS5wbmciLCJpYXQiOjE3NjMxMjY5MzQsImV4cCI6NDkxNjcyNjkzNH0.nXkBMynqZDAo26uhYYkdhFxTZn7DIXzU3lqTomgemdw';
    v_cat_normalface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_normalface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X25vcm1hbGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MDY5LCJleHAiOjQ5MTY3MjcwNjl9.X2x0aS73yBbT0eSb2FuOqbBSBTPdymTRMRtMZ8Iw4TE';
    v_cat_sadface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_sadface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X3NhZGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MDkzLCJleHAiOjgwNzAzMjcwOTN9.Xh_GXNPVIzOvxTaxSRFK9MyIjM-IA7xaPPIYL5NNoYA';

    
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
        v_base_body_url      := v_dog_body_url;
        v_superhappyface     := v_dog_superhappyface_url;
        v_happyface          := v_dog_happyface_url;
        v_normalface         := v_dog_normalface_url;
        v_sadface            := v_dog_sadface_url;
    ELSE -- 預設為 Cat
        v_base_body_url      := v_cat_body_url;
        v_superhappyface     := v_cat_superhappyface_url;
        v_happyface          := v_cat_happyface_url;
        v_normalface         := v_cat_normalface_url;
        v_sadface            := v_cat_sadface_url;
    END IF;

    -- 3. 根據 HP 決定臉部表情 URL
    v_final_face_url := CASE
            WHEN v_pet_record.hp = 100 THEN v_superhappyface
            WHEN v_pet_record.hp >= 75 THEN v_happyface
            WHEN v_pet_record.hp >= 30 THEN v_normalface
            ELSE v_sadface           
    END;

    v_status_text := CASE
        WHEN v_pet_record.hp = 100 THEN '非常活躍'
        WHEN v_pet_record.hp >= 75 THEN '活躍'
        WHEN v_pet_record.hp >= 30 THEN '一般般'
        ELSE '該運動了'
    END;

    -- 4. 查詢所有裝備的圖片 URL
    RETURN (
        SELECT jsonb_build_object(
            'base_body', v_base_body_url,
            'face', v_final_face_url,
            'top', COALESCE(top.item_url, v_default_empty_url),
            'pants', COALESCE(pants.item_url, v_default_empty_url),
            'shoes', COALESCE(shoes.item_url, v_default_empty_url),
            'accessory', COALESCE(acc.item_url, v_default_empty_url),   
            'status_text', v_status_text
        )
        FROM (SELECT 1) AS dummy
        LEFT JOIN internal.clothes AS top ON top.id = v_pet_record.equipped_top_id
        LEFT JOIN internal.clothes AS pants ON pants.id = v_pet_record.equipped_pants_id
        LEFT JOIN internal.clothes AS shoes ON shoes.id = v_pet_record.equipped_shoes_id
        LEFT JOIN internal.clothes AS acc ON acc.id = v_pet_record.equipped_accessory_id
    );
END;
$$;