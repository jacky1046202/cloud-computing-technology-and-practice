CREATE OR REPLACE FUNCTION public.get_user_profile(p_user_id uuid)
RETURNS table (
    id uuid,
    email text,
    gender e.gender,
    relationship e.relationship_status,
    dob date,
    points money
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
        SELECT 
            u.id, 
            u.email,
            u.gender, 
            u.relationship, 
            u.dob, 
            COALESCE(a.points, '0.00'::money) AS points
        FROM 
            public.users AS u
        LEFT JOIN   
            internal.accounts AS a ON u.id = a.user_id
        WHERE 
            u.id = p_user_id;
    
END;
$$