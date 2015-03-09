with AUnit.Test_Cases.Registration;
 use AUnit.Test_Cases.Registration;

with AUnit.Assertions;             use AUnit.Assertions;

with Interfaces;                   use Interfaces;

-- needed only on hosts when the package is not declared Pure in the spec.
with AVR.Real_Time;
pragma Elaborate_All (AVR.Real_Time);


package body AVR.Real_Time.Tests_1s is

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
                          Second => 34);
      Assert (Secs = 60.0+34.0,
              "seconds_of (1m34s) (" & Secs'Img & ")");

      Secs := Seconds_Of (Hour => 23,
                          Minute => 59,
                          Second => 59);
      Assert (Secs = (23.0*60.0+59.0)*60.0+59.0,
              "seconds_of (1day) (" & Secs'Img & ")");
   end Test_Seconds_Of;


   procedure Test_Split_S (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Hours : constant := 3600.0;
      Minutes : constant := 60.0;

      H : Hour_Number;
      M : Minute_Number;
      S : Second_Number;
      Secs : Day_Duration;
   begin
      Secs := 0.0 * Hours + 0.0 * Minutes + 0.0;
      Split (Secs, H, M, S);
      Assert (H = 0, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);

      Secs := 0.0 * Hours + 0.0 * Minutes;
      Split (Secs, H, M, S);
      Assert (H = 0, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);

      Secs := 3.0 * Hours + 34.0 * Minutes + 12.0;
      Split (Secs, H, M, S);
      Assert (H = 3, "hour" & H'Img);
      Assert (M = 34, "min" & M'Img);
      Assert (S = 12, "sec" & S'Img);

      Secs := 12.0 * Hours + 0.0 * Minutes;
      Split (Secs, H, M, S);
      Assert (H = 12, "hour" & H'Img);
      Assert (M = 0, "min" & M'Img);
      Assert (S = 0, "sec" & S'Img);
   end Test_Split_S;


   procedure Test_Split_F (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (False, "test Split_F not yet written");
   end Test_Split_F;


   procedure Test_Split_D (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (False, "test Split_D not yet written");
   end Test_Split_D;


   procedure Test_Time_Of (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Tm : Time;
      -- day difference references by MS-Excel
   begin
      Tm := Time_Of (0, 1, 1); -- jan 1st 2000
      Assert (Tm.Year = 0, "Year of Jan 1st 2000");
      Assert (Tm.Month = 1, "month of Jan 1st 2000");
      Assert (Tm.Day = 1,  "day of Jan 1st 2000");

      Tm := Time_Of (1, 1, 1);

      Tm := Time_Of (2, 1, 1);

      Tm := Time_Of (3, 1, 1);

      Tm := Time_Of (4, 1, 1);

      Tm := Time_Of (5, 1, 1);

      Tm := Time_Of (6, 8, 3);

      Tm := Time_Of (-1, 1, 1);

      Tm := Time_Of (-4, 1, 1);

      Tm := Time_Of (-5, 1, 1);

      Tm := Time_Of (-30, 1, 1);
   end Test_Time_Of;


   Tm_1 : constant Time := Time_Of (6, 3, 20, 20, 30, 45);
   -- 2006-03-20 20:30:45
   Tm_2 : constant Time := Time_Of (6, 3, 21,  0, 42, 59);


   procedure Test_Less (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_1 < Tm_2, "test Less");
   end Test_Less;

   procedure Test_Less_Eq (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_1 <= Tm_2, "test Less_Eq");
      Assert (Tm_1 <= Tm_1, "test Less_Eq");
   end Test_Less_Eq;

   procedure Test_Greater (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_2 > Tm_1, "test Greater");
   end Test_Greater;

   procedure Test_Greater_Eq (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Tm_2 >= Tm_1, "test Greater_Eq");
      Assert (Tm_1 >= Tm_1, "test Greater_Eq");
   end Test_Greater_Eq;

   procedure Test_Add (T : in out AUnit.Test_Cases.Test_Case'Class) is
      Tm : Time;
   begin
      -- Tm_1 = 2006-03-20 20:30:45
      Tm := Tm_1 + 123.0;
      Assert (Tm > Tm_1, "Add, Greater");
      Assert (Tm.Year  =  6, "Add, Year T");
      Assert (Tm.Month =  3, "Add, month T");
      Assert (Tm.Day   = 20, "Add, day T");
      Assert (Tm.Hour  = 20, "Add, hour T");
      Assert (Tm.Min   = 32, "Add, min T");
      Assert (Tm.Sec   = 48, "Add, sec T");
      Tm := Tm_1 + 29*60.0 + 15.0;
      Assert (Tm > Tm_1, "Add, Greater");
      Assert (Tm.Year  =  6, "Add, Year T");
      Assert (Tm.Month =  3, "Add, month T");
      Assert (Tm.Day   = 20, "Add, day T");
      Assert (Tm.Hour  = 21, "Add, hour T");
      Assert (Tm.Min   =  0, "Add, min T");
      Assert (Tm.Sec   =  0, "Add, sec T");
   end Test_Add;


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

   -- "HH:MM:SS"
   procedure Test_Time_Image_Short (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Time_Image_Short (Tm_1) = "203045", "test Time_Image_Short 1");
      Assert (Time_Image_Short (Tm_2) = "004259", "test Time_Image_Short 2");
   end Test_Time_Image_Short;

   -- "YYYY-MM-DD"
   procedure Test_Date_Image_Short (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Date_Image_Short (Tm_1) = "060320", "test Date_Image_Short Tm1");
      Assert (Date_Image_Short (Tm_2) = "060321", "test Date_Image_Short Tm2");
   end Test_Date_Image_short;


   procedure Test_Value_T (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Assert (Value ("2006-03-20 20:30:45") = Tm_1, "test Value_T");
      Assert (Value ("2006-03-21 00:42.59") = Tm_2, "test Value_T");
   end Test_Value_T;


   function Name (T : Test_Case) return String_Access is
   begin
      return new String'("Time structure");
   end Name;


   procedure Register_Tests (T : in out Test_Case) is
   begin
      Register_Routine (T, Test_Seconds'Access, "test Seconds");
      Register_Routine (T, Test_Seconds_Of'Access, "test Seconds_Of");
      Register_Routine (T, Test_Split_S'Access, "test Split (Seconds)");
      Register_Routine (T, Test_Split_F'Access, "test Split (Full)");
      Register_Routine (T, Test_Split_D'Access, "test Split (Date)");
      Register_Routine (T, Test_Time_Of'Access, "test Time_Of");
      Register_Routine (T, Test_Add'Access, "test '+'");
      Register_Routine (T, Test_Less'Access, "test '<'");
      Register_Routine (T, Test_Less_Eq'Access, "test '<='");
      Register_Routine (T, Test_Greater'Access, "test '>'");
      Register_Routine (T, Test_Greater_Eq'Access, "test '>='");
      Register_Routine (T, Test_Minutes'Access, "test Minutes");
      Register_Routine (T, Test_Hours'Access, "test Hours");
      Register_Routine (T, Test_Image_T'Access, "test Image_t");
      Register_Routine (T, Test_Time_Image'Access, "test Time_Image");
      Register_Routine (T, Test_Date_Image'Access, "test Date_Image");
      Register_Routine (T, Test_Time_Image_Short'Access, "test Time_Image_Short");
      Register_Routine (T, Test_Date_Image_Short'Access, "test Date_Image_Short");
      Register_Routine (T, Test_Value_T'Access, "test Value_T");
   end Register_Tests;

end AVR.Real_Time.Tests_1s;
