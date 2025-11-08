CREATE OR REPLACE FUNCTION public.new_exercise_v2(
    p_distance float4,
    p_exercise_time int2,
    p_calories float4,
    p_description varchar(100) DEFAULT '',
    p_user_id uuid DEFAULT NULL  -- 可選，用於 service key 呼叫
)
RETURNS jsonb  -- 回傳更新後的 HP / 獲得的points
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid := COALESCE(p_user_id, auth.uid());
    v_pet_id uuid;
    v_new_hp int;
    v_hp_restored INT := 10;
    v_points_earned money := 10;
BEGIN
    -- 安全檢查：auth.uid() 不可為空
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: user not logged in';
    END IF;
    
    -- 寫入運動紀錄
    INSERT INTO public.records (id, user_id, distance, exercise_time, calories, description, created_at)
    VALUES (gen_random_uuid(), v_user_id, p_distance, p_exercise_time, p_calories, p_description, NOW());

    -- 取得該使用者的寵物
    SELECT id INTO v_pet_id FROM public.pets WHERE user_id = v_user_id;

    IF v_pet_id IS NULL THEN
        RAISE EXCEPTION 'No pet found for user %', v_user_id;
    END IF;

    -- 提升 HP，假設上限為 100
    UPDATE public.pets
    SET hp = LEAST(hp + v_hp_restored, 100),
        updated_at = NOW()
    WHERE id = v_pet_id
    RETURNING hp INTO v_new_hp;

    -- 依 HP 門檻更新外觀
    -- 外觀分級：level 1: 75-100, level 2: 30-74, level 3: 0-29
    -- 回傳更新後的 HP

    -- 插入或更新 'internal.accounts'
    INSERT INTO internal.accounts (id, user_id, points)
    VALUES (gen_random_uuid(), v_user_id, v_points_earned)
    
    -- 如果 'user_id' 已經存在 (違反 unique_user_id 規則)
    ON CONFLICT (user_id) 
    
    -- 則執行 UPDATE
    DO UPDATE SET 
      -- 將現有的 points 加上 v_points_earned
      points = accounts.points + v_points_earned;
    
    -- UPDATE internal.accounts AS a
    -- SET points = points + v_points_earned
    -- WHERE a.user_id = p_user_id;

    RETURN jsonb_build_object(
        'new_hp', v_new_hp,
        'points_earned', v_points_earned::numeric
    );
END;
$$;

-- 權限設定：僅讓 authenticated 使用
-- REVOKE ALL ON FUNCTION public.new_exercise(timestamptz, timestamptz, varchar, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.new_exercise_v2(float4, int2, float4, varchar, uuid) TO authenticated, anon;
