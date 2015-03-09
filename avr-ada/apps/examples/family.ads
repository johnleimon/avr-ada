with Interfaces;                   use Interfaces;
package Family is

   type Parent is tagged private;
   procedure Image (This : Parent);
   function Create (Id : Unsigned_8) return Parent;

   type Child is new Parent with private;
   overriding procedure Image (This : Child);
   overriding function Create (Id : Unsigned_8) return Child;


private
   type Parent is tagged record
      Id : Unsigned_8;
   end record;

   type Child is new Parent with record
      Data : Unsigned_8;
   end record;
end Family;
