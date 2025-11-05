CREATE OR REPLACE FUNCTION get_records_summary(
    p_user_id uuid,
    p_start_date timestamptz,
    p_end_date timestamptz
)
RETURNS json  -- 直接回傳一個 JSON 物件
LANGUAGE sql
AS $$
    SELECT json_build_object(
        'total_distance', COALESCE(SUM(distance), 0),
        'total_time', COALESCE(SUM(exercise_time), 0),
        'total_calories', COALESCE(SUM(calories), 0)
    )
    FROM public.records
    WHERE user_id = p_user_id
      AND created_at >= p_start_date
      AND created_at < p_end_date;
$$;

-- 授權給已登入的使用者
GRANT EXECUTE ON FUNCTION public.get_records_summary(uuid, timestamptz, timestamptz) TO authenticated;
