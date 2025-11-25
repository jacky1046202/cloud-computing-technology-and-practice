CREATE OR REPLACE FUNCTION public.get_shop_items(
    p_user_id uuid,
    p_category_name e.item_category,
    p_search_text text DEFAULT ''
)
RETURNS TABLE (
    store_item_id uuid,
    item_id uuid,
    name text,
    price numeric,
    item_status text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet record;
BEGIN
    -- 1. 獲取用戶的寵物
    SELECT * INTO v_pet 
    FROM public.pets p
    WHERE p.user_id = p_user_id 
    LIMIT 1;

    -- 2. 查詢、JOIN 並回傳結果
    RETURN QUERY
    SELECT 
        s.id AS store_item_id,
        c.id AS item_id,
        c.name::text,
        s.price::numeric,
        
        -- 核心邏輯：判斷狀態
        CASE
            WHEN c.id = v_pet.equipped_top_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_pants_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_shoes_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_accessory_id THEN 'equipped'
            
            WHEN EXISTS (
                SELECT 1 
                FROM public.storage_items si
                WHERE si.owner_id = p_user_id AND si.item_id = c.id
            ) THEN 'owned'
            
            ELSE 'unowned'
        END AS item_status
        
    FROM 
        public.store_items s
    JOIN 
        internal.clothes c ON s.ref_id = c.id AND s.item_type = 'Clothes'
    WHERE
        c.category_name = p_category_name AND (p_search_text = '' OR c.name ILIKE '%' || p_search_text || '%');
        
END;
$$;
