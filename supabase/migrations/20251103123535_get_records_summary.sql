CREATE OR REPLACE FUNCTION public.get_records_summary(
    p_user_id uuid,
    p_start_date timestamptz,
    p_end_date timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_distance float4;
    v_total_time int; -- 分鐘數
    v_total_calories float4;
BEGIN
    SELECT 
        -- 使用 COALESCE 防止 NULL
        COALESCE(SUM(distance), 0),
        COALESCE(SUM(exercise_time), 0),
        COALESCE(SUM(calories), 0)
    INTO 
        v_total_distance,
        v_total_time,
        v_total_calories
    FROM 
        public.records
    WHERE 
        user_id = p_user_id
        -- [!!] 修正：改用 start_time 來篩選日期區間
        AND start_time >= p_start_date 
        AND start_time < p_end_date;

    RETURN jsonb_build_object(
        'total_distance', v_total_distance,
        'total_exercise_time', v_total_time,
        'total_calories', v_total_calories
    );
END;
$$;