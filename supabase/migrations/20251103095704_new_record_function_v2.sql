CREATE OR REPLACE FUNCTION public.new_exercise_v2(
    p_distance float4,
    p_calories float4,
    p_description varchar(100) DEFAULT '',
    p_start_time timestamptz DEFAULT NULL, 
    p_end_time timestamptz DEFAULT NULL,
    p_user_id uuid DEFAULT NULL  -- 可選，用於 service key 呼叫
)
RETURNS jsonb  -- 回傳更新後的 HP / 獲得的points
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, internal
AS $$
DECLARE
    v_user_id uuid := COALESCE(p_user_id, auth.uid());
    v_pet_id uuid;
    v_new_hp int;
    v_hp_restored INT := 10;
    
    -- 計算代幣用的變數
    v_distance_bonus float4 := 0;
    v_points_multiplier float4;
    v_calculated_points numeric;
    
    -- 計算時間用的變數
    v_exercise_time int;
BEGIN
    -- 安全檢查
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: user not logged in';
    END IF;

    -- [!!] 1. 時間驗證與計算
    IF p_start_time IS NOT NULL AND p_end_time IS NOT NULL THEN
        -- A. 合理性檢查
        IF p_start_time >= p_end_time THEN
            RAISE EXCEPTION '結束時間必須晚於開始時間';
        END IF;
        
        -- B. 重疊檢查 (防止重複灌水)
        IF EXISTS (
            SELECT 1 FROM public.records
            WHERE user_id = v_user_id
            AND (start_time, end_time) OVERLAPS (p_start_time, p_end_time)
        ) THEN
            RAISE EXCEPTION '此時段已有運動紀錄，請勿重複填寫';
        END IF;
        
        -- C. 自動計算分鐘數 (後端算才是最準的)
        v_exercise_time := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 60;
    ELSE
        v_exercise_time := 0; 
    END IF;

    -- [!!] 2. 代幣計算 (距離加成公式)
    -- 規則：卡路里 × (0.1 + 距離加成)
    IF p_distance > 15 THEN v_distance_bonus := 0.3;
    ELSIF p_distance > 10 THEN v_distance_bonus := 0.2;
    ELSIF p_distance > 5 THEN v_distance_bonus := 0.1;
    ELSE v_distance_bonus := 0;
    END IF;

    v_points_multiplier := 0.1 + v_distance_bonus;
    v_calculated_points := ROUND(p_calories * v_points_multiplier);

    -- 3. 寫入資料庫
    INSERT INTO public.records (
        id, user_id, distance, exercise_time, calories, description, 
        created_at, start_time, end_time
    )
    VALUES (
        gen_random_uuid(), v_user_id, p_distance, v_exercise_time, p_calories, p_description, 
        NOW(), p_start_time, p_end_time
    );

    -- 4. 寵物回血
    SELECT id INTO v_pet_id FROM public.pets WHERE user_id = v_user_id;
    IF v_pet_id IS NOT NULL THEN
        UPDATE public.pets
        SET hp = LEAST(hp + v_hp_restored, 100), updated_at = NOW()
        WHERE id = v_pet_id
        RETURNING hp INTO v_new_hp;
    ELSE
        v_new_hp := NULL;
    END IF;

    -- 5. 發放代幣 (使用 UPSERT 防止新用戶沒錢包)
    INSERT INTO internal.accounts (id, user_id, points)
    VALUES (gen_random_uuid(), v_user_id, v_calculated_points::money)
    ON CONFLICT (user_id) 
    DO UPDATE SET points = accounts.points + EXCLUDED.points;

    -- 6. 回傳結果
    RETURN jsonb_build_object(
        'new_hp', v_new_hp,
        'points_earned', v_calculated_points
    );
END;
$$;

-- 權限設定：僅讓 authenticated 使用
-- REVOKE ALL ON FUNCTION public.new_exercise(timestamptz, timestamptz, varchar, uuid) FROM PUBLIC;
-- GRANT EXECUTE ON FUNCTION public.new_exercise_v2(float4, int2, float4, varchar, uuid) TO authenticated, anon;
