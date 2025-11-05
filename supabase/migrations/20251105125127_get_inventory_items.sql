CREATE OR REPLACE FUNCTION public.get_inventory_items(
    p_user_id uuid,
    p_category_name e.item_category -- 接收 'top', 'pants', 'shoes', 'accessory'
)
RETURNS TABLE (
    item_id uuid,        -- 物品本身的 ID (來自 internal.clothes)
    name text,
    price numeric,
    item_status text     -- 'equipped' (已裝備), 'standby' (待裝備)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_pet record;
BEGIN
    -- 1. 獲取用戶的寵物，用於檢查「已裝備」
    SELECT * INTO v_pet 
    FROM public.pets p
    WHERE p.user_id = p_user_id 
    LIMIT 1;

    -- 2. 查詢、JOIN 並回傳結果
    RETURN QUERY
    SELECT 
        c.id AS item_id,
        c.name::text,
        -- 從 store_items 獲取價格。
        -- 使用 LEFT JOIN 以防物品已下架，但用戶仍擁有
        s.price::numeric,
        
        -- 核心邏輯：判斷狀態
        CASE
            -- 檢查是否已裝備
            WHEN c.id = v_pet.equipped_top_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_pants_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_shoes_id THEN 'equipped'
            WHEN c.id = v_pet.equipped_accessory_id THEN 'equipped'
            
            ELSE 'standby'
        END AS item_status
        
    FROM 
        public.storage_items si -- 查詢的主體是 storage_items
    
    -- JOIN 物品資料表 (Clothes) 來獲取名稱和分類
    JOIN 
        internal.clothes c ON si.item_id = c.id
        
    -- LEFT JOIN 商店資料表 (store_items) 來獲取價格
    LEFT JOIN 
        public.store_items s ON c.id = s.ref_id
                              AND s.item_type = 'Clothes'
    WHERE
        -- 顯示當前用戶擁有的物品
        si.owner_id = p_user_id
        
        -- 並且根據前端傳入的類別名稱進行過濾
        AND c.category_name = p_category_name;
        
END;
$$;

