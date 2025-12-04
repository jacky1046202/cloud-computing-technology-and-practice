CREATE OR REPLACE FUNCTION public.delete_record(
    p_user_id uuid,
    p_record_id uuid    
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.records 
    WHERE user_id = p_user_id AND id = p_record_id;
    
    IF FOUND THEN
        RETURN true;
    ELSE 
        RETURN false;
    
    END IF;
END;
$$;
