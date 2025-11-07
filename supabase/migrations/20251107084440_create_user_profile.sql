CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile public.users;
BEGIN
  INSERT INTO public.users(
      id,
      email,
      gender,
      relationship,
      dob
  )
  VALUES (
      auth.uid(), 
      auth.email(),
      NULL, 
      NULL, 
      NULL
  )
  -- 根據 email 欄位的 "unique" 索引來判斷衝突
  ON CONFLICT (email) 
  -- 執行一個 dummy update (把 email 設成它自己)
  -- 這是為了讓我們能夠在下一步使用 RETURNING
  DO UPDATE SET email = EXCLUDED.email

  -- 無論是 INSERT 還是 UPDATE，都回傳該行
  RETURNING * INTO v_profile;
  
  RETURN v_profile;
END;
$$;