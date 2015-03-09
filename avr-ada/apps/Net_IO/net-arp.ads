private with Ada.Unchecked_Conversion;
private with Interfaces;
private with Net.Buffer;
private with Net.Ethernet;


package Net.ARP is

   --
   --  ARP database
   --
   type Base_ARP_Entry_Index is private;
   Not_Found : constant Base_ARP_Entry_Index;

   function Index_Of_IP (IP : IP_Addr_Type) return Base_ARP_Entry_Index;
   function MAC_Of_Index (I : Base_ARP_Entry_Index) return MAC_Addr_Type;
   function MAC_Of_IP (IP : IP_Addr_Type) return MAC_Addr_Type;
   procedure Update_ARP_Table (New_MAC : MAC_Addr_Type;
                               New_IP  : IP_Addr_Type);

   --
   --  ethernet communication
   --
   procedure Init;
   --  Initialize the ARP database.  Must be called before any other
   --  procedure of this package.

   procedure Handle_Incoming_Packet;
   --  Assumes a valid IP or ARP packet in the incoming buffer.  The
   --  ARP tables is refresehed from the source IP and MAC addresses.

   procedure Request (Dest_IP : IP_Addr_Type);
   --  Send an ARP request for the Dest_IP.

   procedure Timed_Flush;
   --  Remove old entries from the ARP table.  This function should be
   --  called every 10 seconds.

   --
   --  debugging support
   --
   procedure Debug_Put_ARP_Table;
   --  print a readable table of know MAC-IP mappings

   --   ?? visible?
   type ARP_Header is private;


private
    --  RfC 826
    --  16.bit: (ar$hrd) Hardware address space (e.g., Ethernet, Packet Radio.)
    --  16.bit: (ar$pro) Protocol address space.
    --          For Ethernet hardware, this is from the set of type fields
    --          ether_typ$<protocol>.
    --   8.bit: (ar$hln) byte length of each hardware address
    --   8.bit: (ar$pln) byte length of each protocol address
    --  16.bit: (ar$op)  opcode (ares_op$REQUEST | ares_op$REPLY)
    --  nbytes: (ar$sha) Hardware address of sender of this packet,
    --          n from the ar$hln field.
    --  mbytes: (ar$spa) Protocol address of sender of this packet,
    --          m from the ar$pln field.
    --  nbytes: (ar$tha) Hardware address of target of this packet (if known).
    --  mbytes: (ar$tpa) Protocol address of target.

    --  http://www.isi.edu/in-notes/iana/assignments/arp-parameters

   use Interfaces;
   use Net.Buffer;
   use Net.Ethernet;


   type Opcode_Type is new U16_NBO;

   ARP_Request         : constant Opcode_Type := (0, 1);
   ARP_Reply           : constant Opcode_Type := (0, 2);
   ARP_Request_Reverse : constant Opcode_Type := (0, 3);
   ARP_Reply_Reverse   : constant Opcode_Type := (0, 4);


   type HW_Type is new U16_NBO;

   Ethernet_10Mb : constant HW_Type := (0, 1);


   type Protocol_Type is new U16_NBO;

   ARP_Proto_IPv4 : constant Protocol_Type := (Hi => 16#08#, Lo => 0);


   type ARP_Header is record
      HW          : HW_Type;       -- Code for Ethernet or other link layer
      Protocol    : Protocol_Type; -- Code for IP or other protocol
      HW_Len      : Unsigned_8;    -- length of HW addr, always 6
      Proto_Len   : Unsigned_8;    -- length of protocol addr, always 4
      Op          : Opcode_Type;   -- Code for Request or Reply
      Src_HW_Addr : MAC_Addr_Type; -- Source MAC Address
      Src_IP_Addr : IP_Addr_Type;  -- Source IP Address
      Tgt_HW_Addr : MAC_Addr_Type; -- Target MAC Adress (0 as addr is searched)
      Tgt_IP_Addr : IP_Addr_Type;  -- Target IP Adresse
   end record;


   type ARP_Package_Type is record
      ETH : Ethernet_Header;
      ARP : ARP_Header;
   end record;


   type ARP_Ptr_Type is access all ARP_Package_Type;

   function Convert is new Ada.Unchecked_Conversion (Source => Buffer_Ptr_Type,
                                                     Target => ARP_Ptr_Type);

   Pkg : constant ARP_Ptr_Type := Convert (MTU_Ptr);


   -----------------------------------------------------------------------------

   Max_ARP_Entries  : constant := 5;

   type Base_ARP_Entry_Index is new Unsigned_8 range 0 .. Max_ARP_Entries;

   Not_Found : constant Base_ARP_Entry_Index := 0;

end Net.ARP;

