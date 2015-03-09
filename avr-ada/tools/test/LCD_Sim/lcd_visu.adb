-- with Hello_Package; use Hello_Package;
with Ada.Text_IO;                  use Ada.Text_IO;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
--with Getopt;

with Config_Files;                 use Config_Files;

with Glib;                         use type Glib.Gint;
                                   use type Glib.Guint32;
with Glib.Error;
with Gdk.Color;                    use Gdk.Color;
with Gdk.GC;
with Gdk.Pixbuf;                   use Gdk.Pixbuf;
with Gdk.Rgb;                      use Gdk.Rgb;
with Gdk.Event;                    use Gdk.Event;
with Gtk.Drawing_Area;             use Gtk.Drawing_Area;
with Gtk.Main;                     use Gtk.Main;
with Gtkada.Handlers;              use Gtkada.Handlers;
with Gtk.Style;                    use Gtk.Style;
with Gtk.Widget;                   use Gtk.Widget;
with Gtk.Window;                   use Gtk.Window;
with Gtk.Label;                    use Gtk.Label;

with Digit_Rows;

package body LCD_Visu is

   package Display is
      Lines : Glib.Gint := 2;
      Chars : Glib.Gint := 16;
      Has_Border : Boolean := True;
   end Display;

   LCD_Data_Default_File : constant String := "lcd.data";
   Config_Filename       : constant String := "lcd.cfg";

   Window      : Gtk_Window;
   Label       : Gtk_Label;
   Bottom      : Gdk_Pixbuf;
   Bottom_File : constant String := "img/bottom16.jpg";
   Top         : Gdk_Pixbuf;
   Top_File    : constant String := "img/top16.jpg";
   Left        : Gdk_Pixbuf;
   Left_File   : constant String := "img/left.jpg";
   Right       : Gdk_Pixbuf;
   Right_File  : constant String := "img/right.jpg";
   -- Background  : Gdk_Pixbuf;
   Frame       : Gdk_Pixbuf;
   Bg_Width    : Glib.Gint := 324;
   Bg_Height   : Glib.Gint := 138;
   DA          : Gtk_Drawing_Area;

   Green_GC    : Gdk.GC.Gdk_GC;

   --   type Char_Images is array (Glib.Gint range 1 .. 8) of Gtk_Image;
   --   Char1  : Char_Images;

   --   type Line_Chars is array (Glib.Gint range 1 .. 16) of Char_Images;
   --   Line1  : Line_Chars;
   --   Line2  : Line_Chars;

   subtype Row_Val is Glib.Gint range 0 .. 31;

   type Pix_Combination is array (Row_Val) of Gdk_Pixbuf;
   Pix    :  Pix_Combination;

   Line1 : String := " <Hallo,  Rolf>                                    ";
   Line2 : String := "                                                   ";


   Timeout_Id : Timeout_Handler_Id := 0;

   --  LCD_Rect : constant Gdk_Rectangle := (X      => 0,
--                                           Y      => 0,
--                                           Width  => Bg_Width,
--                                           Height => Bg_Height);


   subtype Char_Row_Idx is Glib.Gint range 1 .. 7;

   type Char_Row is array (Char_Row_Idx) of Glib.Gint;

   type Table is array (Character) of Char_Row;

   Chrtbl : constant Table :=
     (Character'Val  (0) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (1) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (2) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (3) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (4) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (5) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (6) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (7) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (8) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val  (9) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (10) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (11) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (12) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (13) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (14) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (15) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (16) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (17) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (18) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (19) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (20) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (21) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (22) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (23) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (24) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (25) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (26) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (27) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (28) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (29) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (30) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (31) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (32) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (33) => ( 4, 4, 4, 4, 4, 0, 4),
      Character'Val (34) => (10,10,10, 0, 0, 0, 0),
      Character'Val (35) => (10,10,31,10,31,10,10),
      Character'Val (36) => ( 4,15,20,14, 5,30, 4),
      Character'Val (37) => (24,25, 2, 4, 8,19, 3),
      Character'Val (38) => (12,18,20, 8,21,18,13),
      Character'Val (39) => (12, 4, 8, 0, 0, 0, 0),
      Character'Val (40) => ( 2, 4, 8, 8, 8, 4, 2),
      Character'Val (41) => ( 8, 4, 2, 2, 2, 4, 8),
      Character'Val (42) => ( 0, 4,21,14,21, 4, 0),
      Character'Val (43) => ( 0, 4, 4,31, 4, 4, 0),
      Character'Val (44) => ( 0, 0, 0, 0,12, 4, 8),
      Character'Val (45) => ( 0, 0, 0,31, 0, 0, 0),
      Character'Val (46) => ( 0, 0, 0, 0, 0,12,12),
      Character'Val (47) => ( 0, 1, 2, 4, 8,16, 0),
      Character'Val (48) => (14,17,19,21,25,17,14),
      Character'Val (49) => ( 4,12, 4, 4, 4, 4,14),
      Character'Val (50) => (14,17, 1, 2, 4, 8,31),
      Character'Val (51) => (31, 2, 4, 2, 1,17,14),
      Character'Val (52) => ( 2, 6,10,18,31, 2, 2),
      Character'Val (53) => (31,16,30, 1, 1,17,14),
      Character'Val (54) => ( 6, 8,16,30,17,17,14),
      Character'Val (55) => (31, 1, 2, 4, 8, 8, 8),
      Character'Val (56) => (14,17,17,14,17,17,14),
      Character'Val (57) => (14,17,17,15, 1, 2,12),
      Character'Val (58) => ( 0,12,12, 0,12,12, 0),
      Character'Val (59) => ( 0,12,12, 0,12, 4, 8),
      Character'Val (60) => ( 2, 4, 8,16, 8, 4, 2),
      Character'Val (61) => ( 0, 0,31, 0,31, 0, 0),
      Character'Val (62) => (16, 8, 4, 2, 4, 8,16),
      Character'Val (63) => (14,17, 1, 2, 4, 0, 4),
      Character'Val (64) => (14,17, 1,13,21,21,14),
      Character'Val (65) => (14,17,17,17,31,17,17),
      Character'Val (66) => (30,17,17,30,17,17,30),
      Character'Val (67) => (14,17,16,16,16,17,14),
      Character'Val (68) => (30,17,17,17,17,17,30),
      Character'Val (69) => (31,16,16,30,16,16,31),
      Character'Val (70) => (31,16,16,30,16,16,16),
      Character'Val (71) => (14,17,16,23,17,17,15),
      Character'Val (72) => (17,17,17,31,17,17,17),
      Character'Val (73) => (14, 4, 4, 4, 4, 4,14),
      Character'Val (74) => ( 7, 2, 2, 2, 2,18,12),
      Character'Val (75) => (17,18,20,24,20,18,17),
      Character'Val (76) => (16,16,16,16,16,16,31),
      Character'Val (77) => (17,27,21,21,17,17,17),
      Character'Val (78) => (17,17,25,21,19,17,17),
      Character'Val (79) => (14,17,17,17,17,17,14),
      Character'Val (80) => (30,17,17,30,16,16,16),
      Character'Val (81) => (14,17,17,17,21,18,13),
      Character'Val (82) => (30,17,17,30,20,18,17),
      Character'Val (83) => (15,16,16,14, 1, 1,30),
      Character'Val (84) => (31, 4, 4, 4, 4, 4, 4),
      Character'Val (85) => (17,17,17,17,17,17,14),
      Character'Val (86) => (17,17,17,17,17,10, 4),
      Character'Val (87) => (17,17,17,21,21,21,10),
      Character'Val (88) => (17,17,10, 4,10,17,17),
      Character'Val (89) => (17,17,17,10, 4, 4, 4),
      Character'Val (90) => (31, 1, 2, 4, 8,16,31),
      Character'Val (91) => (14, 8, 8, 8, 8, 8,14),
      Character'Val (92) => (17,10,31, 4,31, 4, 4),
      Character'Val (93) => (14, 2, 2, 2, 2, 2,14),
      Character'Val (94) => ( 4,10,17, 0, 0, 0, 0),
      Character'Val (95) => ( 0, 0, 0, 0, 0, 0,31),
      Character'Val (96) => ( 8, 4, 2, 0, 0, 0, 0),
      Character'Val (97) => ( 0, 0,14, 1,15,17,15),
      Character'Val (98) => (16,16,22,25,17,17,30),
      Character'Val (99) => ( 0, 0,14,16,16,17,14),
      Character'Val (100) => ( 1, 1,13,19,17,17,15),
      Character'Val (101) => ( 0, 0,14,17,31,16,14),
      Character'Val (102) => ( 6, 9, 8,28, 8, 8, 8),
      Character'Val (103) => ( 0, 0,15,17,15, 1,14),
      Character'Val (104) => (16,16,22,25,17,17,17),
      Character'Val (105) => ( 4, 0,12, 4, 4, 4,14),
      Character'Val (106) => ( 2, 6, 2, 2, 2,18,12),
      Character'Val (107) => (16,16,18,20,24,20,18),
      Character'Val (108) => (12, 4, 4, 4, 4, 4,14),
      Character'Val (109) => ( 0, 0,26,21,21,17,17),
      Character'Val (110) => ( 0, 0,22,25,17,17,17),
      Character'Val (111) => ( 0, 0,14,17,17,17,14),
      Character'Val (112) => ( 0, 0,30,17,30,16,16),
      Character'Val (113) => ( 0, 0,13,19,15, 1, 1),
      Character'Val (114) => ( 0, 0,22,25,16,16,16),
      Character'Val (115) => ( 0, 0,15,16,14, 1,30),
      Character'Val (116) => ( 8, 8,28, 8, 8, 9, 6),
      Character'Val (117) => ( 0, 0,17,17,17,19,13),
      Character'Val (118) => ( 0, 0,17,17,17,10, 4),
      Character'Val (119) => ( 0, 0,17,17,21,21,10),
      Character'Val (120) => ( 0, 0,17,10, 4,10,17),
      Character'Val (121) => ( 0, 0,17,17,15, 1,14),
      Character'Val (122) => ( 0, 0,31, 2, 4, 8,31),
      Character'Val (123) => ( 2, 4, 4, 8, 4, 4, 2),
      Character'Val (124) => ( 4, 4, 4, 4, 4, 4, 4),
      Character'Val (125) => ( 8, 4, 4, 2, 4, 4, 8),
      Character'Val (126) => ( 0, 4, 2,31, 2, 4, 0),
      Character'Val (127) => ( 0, 4, 8,31, 8, 4, 0),
      Character'Val (128) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (129) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (130) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (131) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (132) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (133) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (134) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (135) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (136) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (137) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (138) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (139) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (140) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (141) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (142) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (143) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (144) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (145) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (146) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (147) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (148) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (149) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (150) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (151) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (152) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (153) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (154) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (155) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (156) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (157) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (158) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (159) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (160) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (161) => ( 0, 0, 0, 0,28,20,28),
      Character'Val (162) => ( 7, 4, 4, 4, 0, 0, 0),
      Character'Val (163) => ( 0, 0, 0, 4, 4, 4,28),
      Character'Val (164) => ( 0, 0, 0, 0,16, 8, 4),
      Character'Val (165) => ( 0, 0, 0,12,12, 0, 0),
      Character'Val (166) => ( 0,31, 1,31, 1, 2, 4),
      Character'Val (167) => ( 0, 0,31, 1, 6, 4, 8),
      Character'Val (168) => ( 0, 0, 2, 4,12,20, 4),
      Character'Val (169) => ( 0, 0, 4,31,17, 1, 6),
      Character'Val (170) => ( 0, 0, 0,31, 4, 4,31),
      Character'Val (171) => ( 0, 0, 2,31, 6,10,18),
      Character'Val (172) => ( 0, 0, 8,31, 9,10, 8),
      Character'Val (173) => ( 0, 0, 0,14, 2, 2,31),
      Character'Val (174) => ( 0, 0,30, 2,30, 2,30),
      Character'Val (175) => ( 0, 0, 0,21,21, 1, 6),
      Character'Val (176) => ( 0, 0, 0, 0,31, 0, 0),
      Character'Val (177) => (31, 1, 5, 6, 4, 4, 8),
      Character'Val (178) => ( 1, 2, 4,12,20, 4, 4),
      Character'Val (179) => ( 4,31,17,17, 1, 2, 4),
      Character'Val (180) => ( 0, 0,31, 4, 4, 4,31),
      Character'Val (181) => ( 2,31, 2, 6,10,18, 2),
      Character'Val (182) => ( 8,31, 9, 9, 9, 9,18),
      Character'Val (183) => ( 4,31, 4,31, 4, 4, 4),
      Character'Val (184) => ( 0,15, 9,17, 1, 2,12),
      Character'Val (185) => ( 8,15,18, 2, 2, 2, 4),
      Character'Val (186) => ( 0,31, 1, 1, 1, 1,31),
      Character'Val (187) => (10,31,10,10, 2, 4, 8),
      Character'Val (188) => ( 0,24, 1,25, 1, 2,28),
      Character'Val (189) => ( 0,31, 1, 2, 4,10,17),
      Character'Val (190) => ( 8,31, 9,10, 8, 8, 7),
      Character'Val (191) => ( 0,17,17, 9, 1, 2,12),
      Character'Val (192) => ( 0,15, 9,21, 3, 2,12),
      Character'Val (193) => ( 2,28, 4,31, 4, 4, 8),
      Character'Val (194) => ( 0,21,21, 1, 1, 2, 4),
      Character'Val (195) => (14, 0,31, 4, 4, 4, 8),
      Character'Val (196) => ( 8, 8, 8,12,10, 8, 8),
      Character'Val (197) => ( 4, 4,31, 4, 4, 8,16),
      Character'Val (198) => ( 0,14, 0, 0, 0, 0,31),
      Character'Val (199) => ( 0,31, 1,10, 4,10,16),
      Character'Val (200) => ( 4,31, 2, 4,14,21, 4),
      Character'Val (201) => ( 2, 2, 2, 2, 2, 4, 8),
      Character'Val (202) => ( 0, 4, 2,17,17,17,17),
      Character'Val (203) => (16,16,31,16,16,16,15),
      Character'Val (204) => ( 0,31, 1, 1, 1, 2,12),
      Character'Val (205) => ( 0, 8,20, 2, 1, 1, 0),
      Character'Val (206) => ( 4,31, 4, 4,21,21, 4),
      Character'Val (207) => ( 0,31, 1, 1,10, 4, 2),
      Character'Val (208) => ( 0,14, 0,14, 0,14, 1),
      Character'Val (209) => ( 0, 4, 8,16,17,31, 1),
      Character'Val (210) => ( 0, 1, 1,10, 4,10,16),
      Character'Val (211) => ( 0,31, 8,31, 8, 8, 7),
      Character'Val (212) => ( 8, 8,31, 9,10, 8, 8),
      Character'Val (213) => ( 0,14, 2, 2, 2, 2,31),
      Character'Val (214) => ( 0,31, 1,31, 1, 1,31),
      Character'Val (215) => (14, 0,31, 1, 1, 2, 4),
      Character'Val (216) => (18,18,18,18, 2, 4, 8),
      Character'Val (217) => ( 0, 4,20,20,21,21,22),
      Character'Val (218) => ( 0,16,16,17,18,20,24),
      Character'Val (219) => ( 0,31,17,17,17,17,31),
      Character'Val (220) => ( 0,31,17,17, 1, 2, 4),
      Character'Val (221) => ( 0,24, 0, 1, 1, 2,28),
      Character'Val (222) => ( 4,18, 8, 0, 0, 0, 0),
      Character'Val (223) => (28,20,28, 0, 0, 0, 0),
      Character'Val (224) => ( 0, 0, 9,21,18,18,13),
      Character'Val (225) => (10, 0,14, 1,15,17,15),
      Character'Val (226) => ( 0,14,17,30,17,30,16),
      Character'Val (227) => ( 0, 0,14,16,12,17,14),
      Character'Val (228) => ( 0,17,17,17,19,29,16),
      Character'Val (229) => ( 0, 0,15,20,18,17,14),
      Character'Val (230) => ( 0, 6, 9,17,17,30,16),
      Character'Val (231) => ( 0,15,17,17,17,15, 1),
      Character'Val (232) => ( 0, 0, 7, 4, 4,20, 8),
      Character'Val (233) => ( 2,26, 2, 0, 0, 0, 0),
      Character'Val (234) => ( 2, 0, 6, 2, 2, 2, 2),
      Character'Val (235) => ( 0,20, 8,20, 0, 0, 0),
      Character'Val (236) => ( 4,14,20,21,14, 4, 0),
      Character'Val (237) => ( 8, 8,28, 8,28, 8,15),
      Character'Val (238) => (14, 0,22,25,17,17,17),
      Character'Val (239) => (10, 0,14,17,17,17,14),
      Character'Val (240) => ( 0,22,25,17,17,30,16),
      Character'Val (241) => ( 0,13,19,17,17,15, 1),
      Character'Val (242) => (14,17,31,17,17,14, 0),
      Character'Val (243) => ( 0, 0, 0, 0,11,21,26),
      Character'Val (244) => ( 0,14,17,17,10,27, 0),
      Character'Val (245) => (10, 0,17,17,17,19,13),
      Character'Val (246) => (31,16, 8, 4, 8,16,31),
      Character'Val (247) => ( 0,31,10,10,10,19, 0),
      Character'Val (248) => (31, 0,17,10, 4,10,17),
      Character'Val (249) => ( 0,17,17,17,17,15, 1),
      Character'Val (250) => ( 1,30, 4,31, 4, 4, 0),
      Character'Val (251) => ( 0,31, 8,15, 9,17, 0),
      Character'Val (252) => ( 0,31,21,31,17,17, 0),
      Character'Val (253) => ( 0, 0, 4, 0,31, 0, 4),
      Character'Val (254) => ( 0, 0, 0, 0, 0, 0, 0),
      Character'Val (255) => (31,31,31,31,31,31,31));



   --  update the string to be displayed
   procedure Update_Linetext;

   --  Expose callback for the drawing area
   function Expose_Cb
     (Widget : access Gtk_Widget_Record'Class;
      Event  : Gdk_Event) return Boolean;

   --  Timeout handler to regenerate the frame
   function Timeout_Handler return Boolean;

   --  read the gifs into pix_bufs
   function Load_Imgs return Boolean;

   --  read parameters from a local config file if present
   procedure Analyze_Local_Config_File;

   --  set parameters read from the command line
   procedure Analyze_Command_Line;


   function Expose_Cb
     (Widget : access Gtk_Widget_Record'Class;
      Event  : Gdk_Event) return Boolean
   is
      --  Num_Bytes_Per_Pixel : constant := 3;
      --  Number of bytes for each pixel (Red, Green, Blue)

      Rowstride : constant Glib.Gint := Get_Rowstride (Frame);
      Pixels    : constant Rgb_Buffer_Access := Get_Pixels (Frame);
      X         : constant Glib.Gint := Get_Area (Event).X;
      Y         : constant Glib.Gint := Get_Area (Event).Y;
      W         : Glib.Gint := Glib.Gint (Get_Area (Event).Width);
      H         : Glib.Gint := Glib.Gint (Get_Area (Event).Height);

   begin
      --  The following tests handle the cases where we try to
      --  redraw the area outside of the background image.
      if X + W > Bg_Width then
         W := Bg_Width - X;
      end if;

      if Y + H > Bg_Height then
         H := Bg_Height - Y;
      end if;

      if W <= 0 or else H <= 0 then
         return True;
      end if;

      Draw_Rgb_Image_Dithalign
        (Drawable  => Get_Window (Widget),
         GC        => Get_Black_GC (Get_Style (Widget)),
         X         => X,
         Y         => Y,
         Width     => W,
         Height    => H,
         Dith      => Dither_Normal,
         Rgb_Buf   => Pixels.all,
         Rowstride => Rowstride,
         Xdith     => X,
         Ydith     => Y);
      return True;
   end Expose_Cb;


   --  Timeout handler to regenerate the frame
   function Timeout_Handler return Boolean
   is
      subtype Width_Range is Integer range 1 .. Integer (Display.Chars);
      subtype Str is String (Width_Range);

      -- a digit is 32 pixels high including 2 separator bits
      -- a digit is 17 pixels wide including 1 separator bit
      Right_X : Glib.Gint;
      Bottom_Y : Glib.Gint;
      X_Off : Glib.Gint;
      Y_Off : Glib.Gint;
   begin
      Right_X := 26 + 17 * Display.Chars;
      Bottom_Y := 35 + 32 * Display.Lines;

      -- Put_Line ("timeout");

      --  read the new text
      Update_Linetext;

      --  set background color #00FF66 alpha=0
      Fill (Frame, 16#00FF6600#);

      if Display.Has_Border then
         ---------------------------------------------------------------------
         --  show the border gifs
         if Display.Chars = 16 then
            Copy_Area
              (Src_Pixbuf  => Top,    Src_X  =>  0,     Src_Y  => 0,
               Width       => 275,    Height => 34,
               Dest_Pixbuf => Frame,  Dest_X => 23,     Dest_Y => 0);
            Copy_Area
              (Src_Pixbuf  => Bottom, Src_X  =>  0,     Src_Y  => 0,
               Width       => 275,    Height => 40,
               Dest_Pixbuf => Frame,  Dest_X => 23,     Dest_Y => Bottom_Y);
         elsif Display.Chars = 6 then
            Copy_Area
              (Src_Pixbuf  => Top,    Src_X  =>  0,     Src_Y  => 0,
               Width       => Right_X - 23, Height => 34,
               Dest_Pixbuf => Frame,  Dest_X => 23,     Dest_Y => 0);
         end if;

         if Display.Lines = 2 then
            Copy_Area
              (Src_Pixbuf  => Left,  Src_X  => 0,       Src_Y  => 0,
               Width       => 23,    Height => 139,
               Dest_Pixbuf => Frame, Dest_X => 0,       Dest_Y => 0);
            Copy_Area
              (Src_Pixbuf  => Right, Src_X  => 0,       Src_Y  => 0,
               Width       => 26,    Height => 139,
               Dest_Pixbuf => Frame, Dest_X => Right_X, Dest_Y => 0);
         elsif Display.Lines = 1 then
            --  32 pixels less than for 2 lines
            Copy_Area
              (Src_Pixbuf  => Left,  Src_X  => 0,       Src_Y  => 0,
               Width       => 23,    Height => 106,
               Dest_Pixbuf => Frame, Dest_X => 0,       Dest_Y => 0);
            Copy_Area
              (Src_Pixbuf  => Right, Src_X  =>   0,     Src_Y  => 0,
               Width       => 26,    Height => 106,
               Dest_Pixbuf => Frame, Dest_X => Right_X, Dest_Y => 0);
         end if;
      end if; -- has_border


      -------------------------------------------------------------------
      --  show the digits
      if Display.Has_Border then
         X_Off := 8;
         Y_Off := 32;
      else
         X_Off := -12;
         Y_Off := 0;
      end if;

      for C in Width_Range loop
         for L in Char_Row_Idx loop
            Copy_Area
              (Src_Pixbuf  => Pix (Chrtbl (Line1(C))(L)),
               Src_X       => 0,
               Src_Y       => 0,
               Width       => 16,
               Height      => 4,
               Dest_Pixbuf => Frame,
               Dest_X      => Glib.Gint(C)*17 + X_Off,
               Dest_Y      => L*4 + Y_Off);
         end loop;
      end loop;

      if Display.Lines > 1 then
         for C in Width_Range loop
            for L in Char_Row_Idx loop
               Copy_Area
                 (Src_Pixbuf  => Pix (Chrtbl (Line2(C))(L)),
                  Src_X       => 0,
                  Src_Y       => 0,
                  Width       => 16,
                  Height      => 4,
                  Dest_Pixbuf => Frame,
                  Dest_X      => Glib.Gint(C)*17 + X_Off,
                  Dest_Y      => L*4 + 32 + Y_Off);
            end loop;
         end loop;
      end if;

      Queue_Draw (DA);
      return True;
   end Timeout_Handler;


   function Load_Imgs return Boolean is
      Error : Glib.Error.GError;
   begin
      Gdk_New_From_File (Bottom, Bottom_File, Error);
      Gdk_New_From_File (Top,    Top_File,    Error);
      Gdk_New_From_File (Left,   Left_File,   Error);
      Gdk_New_From_File (Right,  Right_File,  Error);

      if Bottom = null or else Top = null or else
        Left = null or else Right = null
      then
         Display.Has_Border := False;
         -- return False;
      end if;

      for J in Pix'Range loop
         -- Gdk_New_From_File (Pix (J), Img (J), Error);
         Pix (J) := Digit_Rows.Get_Pixbuf (Digit_Rows.Pixels (J));
         if Pix (J) = null then
            return False;
         end if;
      end loop;
      return True;
   end Load_Imgs;


   --  update the string to be displayed
   procedure Update_Linetext is
      LCD_Cfg_Default_File  : constant String := "lcd.cfg";
      -- LCD_Cfg  : Configuration_Type;
      LCD_Data : Configuration_Type;

      Read_Str : String (1..100);
      Read_Len : Natural := 0;
   begin
      Open (LCD_Data, LCD_Data_Default_File, Error_Handling => Raise_Exception);
      Read (LCD_Data, "show.text", Read_Str, Read_Len,
            Error_Handling => Raise_Exception);
      if Read_Len < Integer (Display.Chars)+1 then
         Line1 (1 .. Read_Len-1) := Read_Str (2 .. Read_Len);
         for I in Read_Len .. Integer (Display.Chars) loop
            Line1(I) := ' ';
         end loop;
      else
         Line1(1..Integer(Display.Chars)) :=
                 Read_Str (2 .. Integer (Display.Chars)+1);
      end if;

      Close (LCD_Data);
   exception
      when others => null;
   end Update_Linetext;


   procedure Destroy (Widget : access Gtk_Widget_Record'Class) is
      pragma Unreferenced (Widget);
   begin
      Gtk.Main.Main_Quit;
   end Destroy;

   --  set parameters found in a local config file if present
   procedure Analyze_Local_Config_File is
      package C renames Config_Files;
      Cfg : C.Configuration_Type;
      function Read is new C.Read_Integer (Glib.Gint);
   begin
      C.Open (Cfg, Config_Filename, Raise_Exception);
      Display.Lines := Read (Cfg, "display.lines", Display.Lines);
      Display.Chars := Read (Cfg, "display.chars", Display.Chars);
      C.Close (Cfg);
   exception
   when Ada.IO_Exceptions.Name_Error |
     Ada.IO_Exceptions.Use_Error               => null;
   end Analyze_Local_Config_File;



   --  set parameters read from the command line
   procedure Analyze_Command_Line
   is
--        use Getopt;
--        CL : Getopt.Object;
--        Found : FoundFlag;
      use Ada.Command_Line;
      Arg : Natural := 0;
      Params : constant Natural := Argument_Count;
   begin
      loop
         Arg := Arg + 1;
         exit when Arg > Params;
         if Argument (Arg) = "-h" then
            Put_Line ("--no_border : don't show PCB frame");
            Put_Line ("--lines : set to number of lines (height)");
            Put_Line ("--chars : set to number of characters (width)");
            exit;
         elsif Argument (Arg) = "--no_border" then
            Display.Has_Border := False;
         elsif Argument (Arg) = "--lines" then
            Arg := Arg + 1;
            declare
               L_Img : constant String := Argument (Arg);
               L_Val : constant Glib.Gint := Glib.Gint'Value (L_Img);
            begin
               Put_Line ("set lines to "& L_Val'Img);
               Display.Lines := L_Val;
            end;
         elsif Argument (Arg) = "--chars" then
            Arg := Arg + 1;
            declare
               C_Img : constant String := Argument (Arg);
               C_Val : constant Glib.Gint := Glib.Gint'Value (C_Img);
            begin
               Put_Line ("set chars to "& C_Val'Img);
               Display.Chars := C_Val;
            end;
         end if;
      end loop;

   end Analyze_Command_Line;


   procedure Run is
   begin
      Analyze_Local_Config_File;
      Analyze_Command_Line;

      --  This is called in all GtkAda applications. Arguments are parsed
      --  from the command line and are returned to the application.
      Gtk.Main.Init;

      --  Creates a new window
      Gtk.Window.Gtk_New (Window);

      --  Here we connect the "destroy" event to a signal handler.
      Widget_Callback.Connect
        (Window, "delete_event",
         Widget_Callback.To_Marshaller (Destroy'Access));
      Widget_Callback.Connect
        (Window, "destroy",
         Widget_Callback.To_Marshaller (Destroy'Access));

      -------------------------------------------------------------------

      if not Load_Imgs then
         Gtk_New (Label, "Images not found");
         Gtk.Window.Add (Window, Label);
      else

         if Display.Has_Border then
            Bg_Height := 75 + 32 * Display.Lines;
            Bg_Width  := 52 + 17 * Display.Chars;
         else
            Bg_Height := 4 + 32 * Display.Lines;
            Bg_Width  := 6 + 17 * Display.Chars;
         end if;

         Gtk_New (DA);
         Size (DA, Bg_Width+2, Bg_Height+2);

         Gtk.Window.Add (Window, DA);

      -------------------------------------------------------------------

         Frame := Gdk.Pixbuf.Gdk_New
           (Colorspace      => Colorspace_RGB,
            Has_Alpha       => False,
            Bits_Per_Sample => 8,
            Width           => Bg_Width,
            Height          => Bg_Height);

         Return_Callback.Connect
           (DA, "expose_event",
            Return_Callback.To_Marshaller (Expose_Cb'Access));

         Timeout_Id := Timeout_Add (100, Timeout_Handler'Access);

      end if;

      Show_All (Window);
      Show (Window);

      -------------------------------------------------------------------
      -- Setup_Color_GC
      declare
         Green : Gdk_Color := Gdk.Color.Parse ("#00FF66");
         Success : Boolean;
      begin
         --  Create a new graphic context. The window must have been
         --  realized first (so that it is associated with some
         --  resources on the Xserver). The GC can then be used for
         --  any window that has the same root window, and same color
         --  depth as Window
         Gdk.GC.Gdk_New (Green_GC, Get_Window (Window));
         Alloc_Color (Colormap   => Gtk.Widget.Get_Default_Colormap,
                      Color      => Green,
                      Writeable  => False,
                      Best_Match => True,
                      Success    => Success);
         Gdk.GC.Set_Foreground (Green_GC, Green);
         Gdk.Gc.Set_Background (Green_GC, Green);
         null;
      end;
      -------------------------------------------------------------------

      declare
         Dead : Boolean;
         Blink_On : Boolean := True;
      begin
         loop
            -- Gtk.Main.Main;
            while Gtk.Main.Events_Pending loop
               Dead := Gtk.Main.Main_Iteration;
            end loop;
            delay 0.1;
            --           if Blink_On then
            --              Put (Frame, Pix(31), 57, 79);
            --           else
            --              Put (Frame, Pix(0), 57, 79);
            --           end if;
            -- Blink_On := not Blink_On;
         end loop;
      end;
   end Run;

end LCD_Visu;


-- compile-command: gnatmake -g -O -Ic:/Programme/GNAT_GPL_2006/include/gtkada lcd_visu-main
--
-- Local Variables: --
-- compile-command: gnatmake --
-- End: --
--
