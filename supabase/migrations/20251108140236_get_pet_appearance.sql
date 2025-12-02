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
    v_final_face_url text;
    v_status_text text;

    v_happyface text;
    v_normalface text;
    v_sadface text;

    v_is_overweight boolean := false;
    
    v_default_empty_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Item/wore/transparent.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJJdGVtL3dvcmUvdHJhbnNwYXJlbnQucG5nIiwiaWF0IjoxNzYyNjEzNDU0LCJleHAiOjQ5MTYyMTM0NTR9.D-qFD78mN0Dk9cWz1tFL7vHGlU0piiMhSxp6V_5Az9I';
    
    v_dog_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTE2LCJleHAiOjQ5MTYyMTM1MTZ9.pdIHeHdcx25TdtPyYnq0qdem4WgIWjNnZyRjmiL7adw';
    v_dog_fat_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_fat_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2ZhdF9ib2R5LnBuZyIsImlhdCI6MTc2NDY3OTk4MiwiZXhwIjo0OTE4Mjc5OTgyfQ.rYKEeBFqdmuwSCWXNplo61V02sv9fcpWKt9w9UUq-Pc';
    v_dog_superhappyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_superhappyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX3N1cGVyaGFwcHlmYWNlLnBuZyIsImlhdCI6MTc2MzEyNzE5NiwiZXhwIjo0OTE2NzI3MTk2fQ.oxRkKPOjElanVQUUfaJPpUbYKxE65TZ28f_ExFlDSV8';
    v_dog_happyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_happyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX2hhcHB5ZmFjZS5wbmciLCJpYXQiOjE3NjMxMjcxODEsImV4cCI6NDkxNjcyNzE4MX0.QKrZiM4-Zj2zY0sabQuDzMNYR1geEslK796OT8iHqiQ';
    v_dog_normalface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_normalface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX25vcm1hbGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MjExLCJleHAiOjY0OTM1MjcyMTF9.Xj9O3hLTWakCNUcvNcaGq-VCSgZnJWyonMDtCaxcQaA';
    v_dog_sadface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Dog/dog_sadface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJEb2cvZG9nX3NhZGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MjMwLCJleHAiOjcwOTI3MTEyMzB9.cCFm6w7hLsLnVs51t4vNZeoDyiPCbUIayFc2xc0pGe8';

    v_cat_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2JvZHkucG5nIiwiaWF0IjoxNzYyNjEzNTM3LCJleHAiOjQ5MTYyMTM1Mzd9.h8yNWt0gGJi5rAFqeubRe_WZEcEoD_7lVGKY2coX48E';
    v_cat_fat_body_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_fat_body.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2ZhdF9ib2R5LnBuZyIsImlhdCI6MTc2NDY4MDAwMywiZXhwIjo0OTE4MjgwMDAzfQ.fwz49MSz-ZgeNaWd8ZCiVfhSMTIXONLUdNkdKvv4Nbk';
    v_cat_superhappyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_superhappyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X3N1cGVyaGFwcHlmYWNlLnBuZyIsImlhdCI6MTc2MzEyNzA1MCwiZXhwIjo4MDcwMzI3MDUwfQ.mY4HZQ5WSYFfVppC7Zuq8K6oinKCKK5bRhzgLbdjWSQ';
    v_cat_happyface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_happyface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X2hhcHB5ZmFjZS5wbmciLCJpYXQiOjE3NjMxMjY5MzQsImV4cCI6NDkxNjcyNjkzNH0.nXkBMynqZDAo26uhYYkdhFxTZn7DIXzU3lqTomgemdw';
    v_cat_normalface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_normalface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X25vcm1hbGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MDY5LCJleHAiOjQ5MTY3MjcwNjl9.X2x0aS73yBbT0eSb2FuOqbBSBTPdymTRMRtMZ8Iw4TE';
    v_cat_sadface_url text := 'https://ndcvnxzsdywwvnwellfx.supabase.co/storage/v1/object/sign/Cat/cat_sadface.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV81YzM0OWUyZC00NjEzLTQ3ODUtOGE4Ny1lNjY0NzdhM2RlNmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJDYXQvY2F0X3NhZGZhY2UucG5nIiwiaWF0IjoxNzYzMTI3MDkzLCJleHAiOjgwNzAzMjcwOTN9.Xh_GXNPVIzOvxTaxSRFK9MyIjM-IA7xaPPIYL5NNoYA';

BEGIN
    -- 1. 獲取寵物
    SELECT * INTO v_pet_record FROM public.pets p WHERE p.user_id = p_user_id LIMIT 1;
    IF v_pet_record IS NULL THEN RAISE EXCEPTION 'Pet not found'; END IF;

    -- 2. 判斷 HP 狀態 & 是否過重 (邏輯核心)
    CASE
        WHEN v_pet_record.hp >= 90 THEN
            v_status_text := '超活躍';
            v_final_face_url := CASE WHEN v_pet_record.species = 'Dog' THEN v_dog_superhappyface_url ELSE v_cat_superhappyface_url END;
            v_is_overweight := false;
            
        WHEN v_pet_record.hp >= 60 THEN
            v_status_text := '活躍';
            v_final_face_url := CASE WHEN v_pet_record.species = 'Dog' THEN v_dog_happyface_url ELSE v_cat_happyface_url END;
            v_is_overweight := false;
            
        WHEN v_pet_record.hp >= 30 THEN
            v_status_text := '一般般';
            v_final_face_url := CASE WHEN v_pet_record.species = 'Dog' THEN v_dog_normalface_url ELSE v_cat_normalface_url END;
            v_is_overweight := false;
            
        ELSE -- HP < 30
            v_status_text := '該運動了';
            v_final_face_url := CASE WHEN v_pet_record.species = 'Dog' THEN v_dog_sadface_url ELSE v_cat_sadface_url END;
            v_is_overweight := true; -- [!!] 標記為過重
    END CASE;

    -- 3. 決定身體圖片 (正常 vs 胖版)
    IF v_pet_record.species = 'Dog' THEN
        IF v_is_overweight THEN
            v_base_body_url := v_dog_fat_body_url; -- 使用胖狗
        ELSE
            v_base_body_url := v_dog_body_url;     -- 使用正常狗
        END IF;
    ELSE -- Cat
        IF v_is_overweight THEN
            v_base_body_url := v_cat_fat_body_url; -- 使用胖貓
        ELSE
            v_base_body_url := v_cat_body_url;     -- 使用正常貓
        END IF;
    END IF;

    -- 4. 回傳 JSON (包含強制脫衣邏輯)
    RETURN (
        SELECT jsonb_build_object(
            'base_body', v_base_body_url,
            'face', v_final_face_url,
            'status_text', v_status_text,
            
            -- [!!] 這裡使用 CASE WHEN 來控制衣服
            -- 如果 v_is_overweight 為 TRUE，強制回傳透明圖 (v_default_empty_url)
            -- 否則回傳原本的裝備圖片
            
            'top', CASE 
                WHEN v_is_overweight THEN v_default_empty_url 
                ELSE COALESCE(top.item_url, v_default_empty_url) 
            END,
            
            'pants', CASE 
                WHEN v_is_overweight THEN v_default_empty_url 
                ELSE COALESCE(pants.item_url, v_default_empty_url) 
            END,
            
            'shoes', CASE 
                WHEN v_is_overweight THEN v_default_empty_url 
                ELSE COALESCE(shoes.item_url, v_default_empty_url) 
            END,
            
            'accessory', CASE 
                WHEN v_is_overweight THEN v_default_empty_url 
                ELSE COALESCE(acc.item_url, v_default_empty_url) 
            END
        )
        FROM (SELECT 1) AS dummy
        LEFT JOIN internal.clothes AS top ON top.id = v_pet_record.equipped_top_id
        LEFT JOIN internal.clothes AS pants ON pants.id = v_pet_record.equipped_pants_id
        LEFT JOIN internal.clothes AS shoes ON shoes.id = v_pet_record.equipped_shoes_id
        LEFT JOIN internal.clothes AS acc ON acc.id = v_pet_record.equipped_accessory_id
    );
END;
$$;