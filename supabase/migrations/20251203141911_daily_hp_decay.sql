CREATE OR REPLACE FUNCTION public.daily_hp_decay()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 更新所有 "昨天沒運動" 的寵物
    UPDATE public.pets
    SET 
        hp = GREATEST(hp - 10, 0), -- 扣 10，使用 GREATEST 確保不低於 0
        updated_at = NOW()
    WHERE user_id NOT IN (
        -- 子查詢：找出 "昨天" 有運動紀錄的 user_id
        SELECT DISTINCT user_id
        FROM public.records
        WHERE start_time >= (CURRENT_DATE - INTERVAL '1 day') -- 昨天 00:00
          AND start_time < CURRENT_DATE                       -- 今天 00:00
    );
END;
$$;

-- 排程名稱：'daily_hp_decay_job'
-- 時間：'0 0 * * *' (每天 00:00 UTC)
-- 執行的指令：SELECT public.daily_hp_decay();
-- 台灣半夜 00:00 執行，要把時間改成 '0 16 * * *'

SELECT cron.schedule(
    'daily_hp_decay_job', -- 任務名稱 (唯一)
    '0 16 * * *',          -- Cron 表達式 (每天午夜)
    'SELECT public.daily_hp_decay()'
);