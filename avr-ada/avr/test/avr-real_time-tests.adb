with AUnit.Test_Cases.Registration;use AUnit.Test_Cases.Registration;
with AUnit.Assertions;             use AUnit.Assertions;
with Interfaces;                   use Interfaces;

-- needed only on hosts if the package is not declared Pure in the spec.
-- pragma Elaborate_All (AVR.Real_Time);

package body AVR.Real_Time.Tests is

   procedure Test_Day_Of_Week (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Tm : Time;
   begin
      Tm := Time_Of (6, 3, 21); -- 2006-03-21 is a Tuesday
      Assert (Day_Of_Week (Tm) = Tuesday, "2006-03-21 is a Tuesday");

      Tm := Time_Of (1, 1, 1);  -- Jan 1st 2001 was a Monday
      Assert (Day_Of_Week (Tm) = Monday, "Jan 1st 2001 is Monday");
   end Test_Day_Of_Week;

   procedure Test_Single_Time_Split
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Hours : constant := 3600.0;
      Minutes : constant := 60.0;

      Tm : Time;
      S : Second_Number;

      D : constant Standard.Duration  := 0.201;

   begin
      Tm.Secs := 5 * Hours + 34 * Minutes + 13.499;
      Assert (Sub_Second (Tm) = 0.499, "Sub_Second (0.499)");
      Assert (Second (Tm) = 13, "Second (13)");
      Assert (Minute (Tm) = 34, "Minute (34)");
      Assert (Hour (Tm) = 5, "Hour (5)");

      Tm.Secs := 0.0 * Hours + 0.0 * Minutes + 0.0;
      Assert (Hour (Tm) = 0, "hour (0)");
      Assert (Minute (Tm) = 0, "min (0)");
      Assert (Second (Tm) = 0, "sec (0)");
      Assert (Sub_Second (Tm) = 0.0, "subs (0.0)");

      Assert (Integer (D) >= 0, "dur->int");
      Assert (Integer (D-0.5) >= 0, "dur->int");

      Tm.Secs := 0.0 * Hours + 0.0 * Minutes + 0.3;
      Assert (Hour (Tm) = 0, "hour (0)");
      Assert (Minute (Tm) = 0, "min (0)");
      Assert (Second (Tm) = 0, "sec (0)");
      Assert (Sub_Second (Tm) = 0.3, "subs (0.3)");

      Tm.Secs := 3.0 * Hours + 34.0 * Minutes + 12.500;
      Assert (Hour (Tm) = 3, "hour (3)");
      Assert (Minute (Tm) = 34, "min (34)");
      Assert (Second (Tm) = 12, "sec (12)");
      Assert (Sub_Second (Tm) = 0.5, "subs (0.5)");

      Tm.Secs := 12.0 * Hours + 0.0 * Minutes + 1.999;
      Assert (Hour (Tm) = 12, "hour (12)");
      Assert (Minute (Tm) = 0, "min (0)");
      S := Second (Tm);
      Assert (Sub_Second (Tm) = 0.999, "subs (0.999)");
      Assert (S = 1, "sec (1)" & S'img);
   end Test_Single_Time_Split;

   procedure Test_Single_Date_Split
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      Tm : Time;
   begin
      Tm.Days := 0;
      Assert (Year (Tm) = 0, "year(0) = 2000");
      Assert (Month (Tm) = 1, "month(0) = Jan");
      Assert (Day (Tm) = 1, "day(0) = 1");

      Tm.Days := 2406;
      Assert (Year (Tm) = 06, "year(2406) = 2006");
      Assert (Month (Tm) = 8, "month(2406) = Aug");
      Assert (Day (Tm) = 3, "day(2406) = 3");
   end Test_Single_Date_Split;

   procedure Test_Seconds (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Seconds (30) = 30.0, "test Seconds(30)");
      Assert (Seconds (85000) = 85000.0, "test Seconds(85000)");
      Assert (Seconds (100_000) = 100_000.0, "test Seconds(100,000)");
      Assert (Seconds (-30) = -30.0, "test Seconds(-30)");
      Assert (Seconds (-40_000) = -40_000.0, "test Seconds(-40_000)");
   end Test_Seconds;

   procedure Test_Seconds_Of (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Secs : Day_Duration;
   begin
      Secs := Seconds_Of (Hour => 1,
                          Minute => 0);
      Assert (Secs = 3600.0, "seconds_of (1 hour) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 0,
                          Minute => 1);
      Assert (Secs = 60.0, "seconds_of (1 min) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 1,
                          Minute => 1,
                          Second => 1);
      Assert (Secs = 3661.0, "seconds_of (1h1m1s) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 23,
                          Minute => 1);
      Assert (Secs = 23.0*60.0*60.0+60.0, "seconds_of (23h1m) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 0,
                          Minute => 0);
      Assert (Secs = 0.0, "seconds_of (0) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 0,
                          Minute => 1,
                          Second => 34,
                          Sub_Second => 0.123);
      Assert (Secs = 60.0+34.0+0.123,
              "seconds_of (1m34s.0123) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 23,
                          Minute => 59,
                          Second => 59,
                          Sub_Second => 1.0);
      Assert (Secs = (23.0*60.0+59.0)*60.0+59.0+1.0,
              "seconds_of (1day) (" & Secs'Img & ")");
   end Test_Seconds_Of;


   procedure Test_Split_S (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Hours : constant := 3600.0;
      Minutes : constant := 60.0;

      H : Hour_Number;
      M : Minute_Number;
      S : Second_Number;
      SS: Second_Duration;
      Secs : Day_Duration;
   begin
      Secs := 0.0 * Hours + 0.0 * Minutes + 0.0;
      Split (Secs, H, M, S, SS);
      Assert (H = 0, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);
      Assert (SS = 0.0, "subs" & SS'Img);

      Secs := 0.0 * Hours + 0.0 * Minutes + 0.99;
      Split (Secs, H, M, S, SS);
      Assert (H = 0, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);
      Assert (SS = 0.99, "subs" & SS'Img);

      Secs := 3.0 * Hours + 34.0 * Minutes + 12.500;
      Split (Secs, H, M, S, SS);
      Assert (H = 3, "hour" & H'Img);
      Assert (M = 34, "min" & M'Img);
      Assert (S = 12, "sec" & S'Img);
      Assert (SS = 0.5, "subs" & SS'Img);

      Secs := 12.0 * Hours + 0.0 * Minutes + 0.001;
      Split (Secs, H, M, S, SS);
      Assert (H = 12, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);
      Assert (SS = 0.001, "subs" & SS'Img);
   end Test_Split_S;

   procedure Test_Split_F (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (False, "test Split_F");
   end Test_Split_F;

   procedure Test_Split_D (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (False, "test Split_D");
   end Test_Split_D;

   procedure Test_Time_Of (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Tm : Time;
      -- day difference references by MS-Excel
   begin
      Tm := Time_Of (0, 1, 1); -- jan 1st 2000
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2000");
      Assert (Tm.Days = 0, "days of Jan 1st 2000");

      Tm := Time_Of (1, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2001");
      Assert (Tm.Days = 366, "days of Jan 1st 2001" & Tm.Days'Img);

      Tm := Time_Of (2, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2002");
      Assert (Tm.Days = 731, "days of Jan 1st 2002" & Tm.Days'Img);

      Tm := Time_Of (3, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2003");
      Assert (Tm.Days = 1096, "days of Jan 1st 2003" & Tm.Days'Img);

      Tm := Time_Of (4, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2004");
      Assert (Tm.Days = 1461, "days of Jan 1st 2004" & Tm.Days'Img);

      Tm := Time_Of (5, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 2005");
      Assert (Tm.Days = 1827, "days of Jan 1st 2005" & Tm.Days'Img);

      Tm := Time_Of (6, 8, 3);
      Assert (Tm.Secs = 0.0, "secs of Aug 3rd 2006");
      Assert (Tm.Days = 2406, "days of Aug 3rd 2006" & Tm.Days'Img);

      Tm := Time_Of (-1, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 1999");
      Assert (Tm.Days = -365, "days of Jan 1st 1999" & Tm.Days'Img);

      Tm := Time_Of (-4, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 1996");
      Assert (Tm.Days = -1_461, "days of Jan 1st 1996" & Tm.Days'Img);

      Tm := Time_Of (-5, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 1995");
      Assert (Tm.Days = -1_826, "days of Jan 1st 1995" & Tm.Days'Img);

      Tm := Time_Of (-30, 1, 1);
      Assert (Tm.Secs = 0.0, "secs of Jan 1st 1970");
      Assert (Tm.Days = -10_957, "days of Jan 1st 1970" & Tm.Days'Img);
   end Test_Time_Of;


   Tm_1 : constant Time := Time_Of (6, 3, 20, 20, 30, 45, 0.123);
   -- 2006-03-20 20:30:45.123
   Tm_2 : constant Time := Time_Of (6, 3, 21,  0, 42, 59, 0.444);

   Time_Span_1 : constant Duration :=
     Duration'(4.0 * 3600 + 12.0 * 60 + 14.321);

   procedure Test_Plus_1 (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_1 + Time_Span_1 = Tm_2,
              "test 2006-03-20 20:30:45.123 + 4:12:14.321");
   end Test_Plus_1;

   procedure Test_Plus_2 (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Time_Span_1 + Tm_1 = Tm_2,
              "test 4:12:14.321 + 2006-03-20 20:30:45.123");
   end Test_Plus_2;

   procedure Test_Minus_1 (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_2 - Time_Span_1 = Tm_1,
              "test 2006-03-21 00:42:59.444 - 4:12:14.321");
   end Test_Minus_1;

   procedure Test_Minus_2 (T : in out AUnit.Test_Cases.Test_Case'Class) is
      TS : constant Duration := Tm_2 - Tm_1;
   begin
      Assert (TS = Time_Span_1, "test Minus_2 (Time_Span_1 =" & Time_Span_1'Img & ", Tm_2 - Tm_1 =" & TS'Img);
      Assert ((Tm_1 + 0.001) - Tm_1 = 0.001, "test Minus_2 (+-0.001)");
   end Test_Minus_2;

   procedure Test_Less (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_1 < Tm_2, "test Less");
   end Test_Less;

   procedure Test_Less_Eq (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_1 <= Tm_2, "test Less_Eq");
      Assert (Tm_1 <= Tm_1, "test Less_Eq");
      Assert (Tm_1 + Time_Span_1 <= Tm_2, "test Less_Eq");
   end Test_Less_Eq;

   procedure Test_Greater (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_2 > Tm_1, "test Greater");
   end Test_Greater;

   procedure Test_Greater_Eq (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_2 >= Tm_1, "test Greater_Eq");
      Assert (Tm_1 >= Tm_1, "test Greater_Eq");
      Assert (Tm_2 >= Tm_1 + Time_Span_1, "test Greater_Eq");
   end Test_Greater_Eq;

   procedure Test_Microseconds (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Microseconds (12345) = 0.012, "test Microseconds");
   end Test_Microseconds;

   procedure Test_Milliseconds (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Milliseconds (50001) = 50.001, "test Milliseconds");
      Assert (Milliseconds (999) = 0.999, "test Milliseconds");
   end Test_Milliseconds;

   procedure Test_Minutes (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Minutes (0) = 0.0, "test Minutes");
      Assert (Minutes (10) = 600.0, "test Minutes");
      Assert (Minutes (-99) = -99.0 * 60.0, "test Minutes");
   end Test_Minutes;

   procedure Test_Hours (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Hours (0) = 0.0, "test Hours");
      Assert (Hours (8) = 8.0 * 3600.0, "test Hours");
      Assert (Hours (-4) = -4.0 * 3600.0, "test Hours");
   end Test_Hours;

   procedure Test_Image_T (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Image (Tm_1) = "2006-03-20 20:30:45", "test Image_T");
      Assert (Image (Tm_2) = "2006-03-21 00:42:59", "test Image_T");
   end Test_Image_T;

   -- "HH:MM:SS"
   procedure Test_Time_Image (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Time_Image (Tm_1) = "20:30:45", "test Time_Image 1");
      Assert (Time_Image (Tm_2) = "00:42:59", "test Time_Image 2");
   end Test_Time_Image;

   -- "YYYY-MM-DD"
   procedure Test_Date_Image (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Date_Image (Tm_1) = "2006-03-20", "test Date_Image");
      Assert (Date_Image (Tm_2) = "2006-03-21", "test Date_Image");
   end Test_Date_Image;

   -- "00,000.000"
   procedure Test_Millisec_Image (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
   begin
      Assert (Millisec_Image (12_345.678) = "12,345.678",
              "test Millisec_Image 1");
      Assert (Millisec_Image (0.001)      = "     0.001",
              "test Millisec_Image 3");
      Assert (Millisec_Image (70_444.4)   = "70,444.400",
              "test Millisec_Image 4");
      Assert (Millisec_Image (55.445)     = "    55.445",
              "test Millisec_Image 2");
   end Test_Millisec_Image;

   procedure Test_Image_D (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Image (Time_Span_1) = "04:12:14", "test Image_D");
   end Test_Image_D;

   -- "HH:MM:SS.000"
   procedure Test_Fract_Image (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Fract_Image (Time_Span_1) = "04:12:14.321", "test Fract_Image");
   end Test_Fract_Image;


   procedure Test_Value_T (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Value ("2006-03-20 20:30:45") = Tm_1, "test Value_D");
      Assert (Value ("2006-03-21 00:42.59") = Tm_2, "test Value_D");
   end Test_Value_T;


   procedure Test_Value_D (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Value ("04:12:14.321") = Time_Span_1, "test Value_D");
   end Test_Value_D;


   ----------
   -- Name --
   ----------

   function Name (T : Test_Case) return String is
   begin
      return "Time structure";
   end Name;

   --------------------
   -- Register_Tests --
   --------------------

   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Day_Of_Week'Access, "test Day_of_week");
      Register_Routine (T, Test_Single_Time_Split'Access,
                        "test single time splits");
      Register_Routine (T, Test_Single_Date_Split'Access,
                        "test single date splits");
      Register_Routine (T, Test_Seconds'Access, "test Seconds");
      Register_Routine (T, Test_Seconds_Of'Access, "test Seconds_Of");
      Register_Routine (T, Test_Split_S'Access, "test Split (Seconds)");
      Register_Routine (T, Test_Split_F'Access, "test Split (Full)");
      Register_Routine (T, Test_Split_D'Access, "test Split (Date)");
      Register_Routine (T, Test_Time_Of'Access, "test Time_Of");
      Register_Routine (T, Test_Plus_1'Access, "test '+'1");
      Register_Routine (T, Test_Plus_2'Access, "test '+'2");
      Register_Routine (T, Test_Minus_1'Access, "test '-'1");
      Register_Routine (T, Test_Minus_2'Access, "test '-'2");
      Register_Routine (T, Test_Less'Access, "test '<'");
      Register_Routine (T, Test_Less_Eq'Access, "test '<='");
      Register_Routine (T, Test_Greater'Access, "test '>'");
      Register_Routine (T, Test_Greater_Eq'Access, "test '>='");
      Register_Routine (T, Test_Microseconds'Access, "test Microseconds");
      Register_Routine (T, Test_Milliseconds'Access, "test Milliseconds");
      Register_Routine (T, Test_Minutes'Access, "test Minutes");
      Register_Routine (T, Test_Hours'Access, "test Hours");
      Register_Routine (T, Test_Image_T'Access, "test Image_t");
      Register_Routine (T, Test_Time_Image'Access, "test Time_Image");
      Register_Routine (T, Test_Date_Image'Access, "test Date_Image");
      Register_Routine (T, Test_Millisec_Image'Access, "test Millisec_Image");
      Register_Routine (T, Test_Image_D'Access, "test Image_D");
      Register_Routine (T, Test_Fract_Image'Access, "test Fract_Image");
      Register_Routine (T, Test_Value_T'Access, "test Value_t");
      Register_Routine (T, Test_Value_D'Access, "test Value_D");
   end Register_Tests;

end AVR.Real_Time.Tests;
