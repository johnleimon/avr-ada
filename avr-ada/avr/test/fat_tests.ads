with Interfaces;        use Interfaces;

package FAT_Tests is

   procedure FAT16_Suite(Sectors, Sects_Per_Cluster, Root_Entries, FATs, Reserved : Unsigned_32);
   procedure FAT32_Suite(Sectors, Sects_Per_Cluster, FATs, Reserved : Unsigned_32);

end FAT_Tests;
