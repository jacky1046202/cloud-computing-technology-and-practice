CREATE OR REPLACE FUNCTION public.select_pet(
    p_species e.species, 
    p_user_id uuid DEFAULT NULL
)
RETURNS uuid -- 回傳新寵物的 ID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid := COALESCE(p_user_id, auth.uid());
    v_pet_id uuid;
BEGIN
    -- 安全檢查：auth.uid() 不可為空
    IF v_user_id IS NULL THEN 
        RAISE EXCEPTION 'Unauthorized: user not logged in';
    END IF;    

    -- 確認使用者沒有寵物
    IF EXISTS (SELECT 1 FROM public.pets WHERE user_id = v_user_id) THEN
        RAISE EXCEPTION 'User % already has a pet', v_user_id;
    END IF;

    -- 建立新寵物
    INSERT INTO public.pets (id, user_id, species, color, hp, created_at, updated_at)
    VALUES (
        gen_random_uuid(), 
        v_user_id, p_species, 
        'default_color', 
        100, 
        now(), 
        now()
    )RETURNING id INTO v_pet_id;    

    RETURN v_pet_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.select_pet(e.species, uuid) TO authenticated, anon;
