CREATE OR REPLACE FUNCTION get_total_distance_today(
    p_user_id uuid DEFAULT NULL
)RETURNS float4
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id uuid := COALESCE(p_user_id, auth.uid()); 
    v_total_distance_today float4;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: user not logged in';
    END IF;

    SELECT SUM(distance) INTO v_total_distance_today
    FROM public.records
    WHERE v_user_id = user_id 
    AND created_at = CURRENT_DATE;
    
    RETURN COALESCE(v_total_distance_today, 0.0);
END;
$$;