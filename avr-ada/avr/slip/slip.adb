-- slip.adb - Mon Aug  9 19:32:58 2010
--
-- (c) Warren W. Gay VE3WWG  ve3wwg@gmail.com
--
-- $Id$
--
-- Protected under:
-- The GNU Lesser General Public License version 2.1 (LGPLv2.1)

with CRC16;

package body Slip is

    Pkt_End :       constant Unsigned_8 := 8#300#;  -- Indicates end of packet
    Pkt_Esc :       constant Unsigned_8 := 8#333#;  -- Indicates byte stuffing
    Pkt_Esc_End :   constant Unsigned_8 := 8#334#;  -- ESC ESC_END means END "data byte"
    Pkt_Esc_Esc :   constant Unsigned_8 := 8#335#;  -- ESC ESC_ESC means ESC "data byte"
    Pkt_Esc_Rpt :   constant Unsigned_8 := 8#336#;  -- Repeat next byte, by next+1 times

    ------------------------------------------------------------------
    -- Open a Context for Slip I/O
    ------------------------------------------------------------------
    procedure Open(Context : in out Slip_Context;
                   Receive : in     Receive_Proc;
                   Transmit : in    Transmit_Proc;
                   Compress : in    Boolean := True;
                   CRC16 :    in    Boolean := True) is
    begin
        Context.Recv        := Receive;
        Context.Xmit        := Transmit;
        Context.Compress    := Compress;
        Context.CRC16       := CRC16;
    end Open;
               
    ------------------------------------------------------------------
    -- INTERNAL - Flush Accumulated Xmit Data
    ------------------------------------------------------------------
    procedure Flush(
        Context :   in      Slip_Context;
        Last_Byte : in      Unsigned_8;
        Count :     in out  Unsigned_8) is
    begin

        if not Context.Compress or else Count <= 4 then
            ----------------------------------------------------------
            -- Send as is, for small counts
            ----------------------------------------------------------
            for X in 1..Count loop
                Context.Xmit(Last_Byte);
            end loop;
        else
            ----------------------------------------------------------
            -- Transmit with a repeat count
            ----------------------------------------------------------
            Context.Xmit(Pkt_Esc);
            Context.Xmit(Pkt_Esc_Rpt);
            Context.Xmit(Last_Byte);
            Context.Xmit(Count);
        end if;

        Count := 0;

    end Flush;

    ------------------------------------------------------------------
    -- INTERNAL - Emit Packet Bytes
    ------------------------------------------------------------------
    procedure Emit(
        Context :   in      Slip_Context;
        Byte :      in      Unsigned_8;
        Last_Byte : in out  Unsigned_8;
        Count :     in out  Unsigned_8) is
    begin

        case Byte is
            when Pkt_End =>
                Flush(Context,Last_Byte,Count);
                Context.Xmit(Pkt_Esc);
                Context.Xmit(Pkt_Esc_End);

            when Pkt_Esc =>
                Flush(Context,Last_Byte,Count);
                Context.Xmit(Pkt_Esc);
                Context.Xmit(Pkt_Esc_Esc);

            when others =>
                if Count > 0 and then Byte /= Last_Byte then
                    Flush(Context,Last_Byte,Count);
                end if;
                if Count = 0 then
                    Last_Byte := Byte;
                end if;
                Count := Count + 1;
        end case;

    end Emit;

    ------------------------------------------------------------------
    -- Transmit a Slip Packet, Optionally Compressed & Optional CRC-16
    ------------------------------------------------------------------
    procedure Transmit(Context : in out Slip_Context; Packet : Packet_Type) is
        Last_Byte : Unsigned_8 := 0;    -- Last data byte considered for compression
        Count :     Unsigned_8 := 0;    -- Count of Last_Byte's
        CRC :       CRC16.CRC_Type;     -- Computed CRC value
    begin

        if Context.CRC16 then
            CRC16.Init(CRC);            -- Initialize CRC-16 value
        end if;

        Context.Xmit(Pkt_End);          -- Initial 'End' flushes out line noise

        for X in Packet'Range loop
            if Context.CRC16 then
                CRC16.Update(CRC,Packet(X));
            end if;
            Emit(Context,Packet(X),Last_Byte,Count);
        end loop;

        if Context.CRC16 then
            Emit(Context,CRC16.CRC_High(CRC),Last_Byte,Count);
            Emit(Context,CRC16.CRC_Low(CRC),Last_Byte,Count);
        end if;

        Flush(Context,Last_Byte,Count);

        Context.Xmit(Pkt_End);

    end Transmit;

    ------------------------------------------------------------------
    -- Receive a Packet into "Packet" Buffer, up to 255 bytes.
    ------------------------------------------------------------------
    procedure Receive(Context : in out Slip_Context;    -- SLIP context
                      Packet :     out Packet_Type;     -- Receiving packet buffer
                      Length :     out Unsigned_8;      -- Return packet length
                      Error  :     out Boolean) is      -- True if packet was truncated/error

        X :         Unsigned_8 := Packet'First;         -- Index into packet buffer
        Byte :      Unsigned_8;                         -- Received byte
        Rpt_Count : Unsigned_8;                         -- Repeat count
        Count :     Unsigned_8 := 0;                    -- Packet byte count
        Truncated : Boolean := False;                   -- True if packet was truncated

        --------------------------------------------------------------
        -- Post Error and Reason Code
        --------------------------------------------------------------
        procedure Post_Error(Reason : Character) is
        begin
            Context.Reason := Reason;
            Error          := True;
        end;

        --------------------------------------------------------------
        -- Stow the data byte into the receiving buffer
        --------------------------------------------------------------
        procedure Stow_Byte is
        begin
            if X <= Packet'Last then                    -- Is receiving buffer full?
                Packet(X) := Byte;                      -- No, then return the data byte
                X := X + 1;                             -- Point to next buffer byte
                Count := X - Packet'First;              -- recompute packet length
            else
                Truncated := True;                      -- Mark returned packet as truncated
                Post_Error('T');
            end if;
        end Stow_Byte;

    begin

        Error := False;                                 -- Assume the "happy path"
        Context.Reason := ' '; 
        Length := 0;

        loop
            exit when Truncated;                        -- Quit if we truncated
            Context.Recv(Byte);                         -- Read a byte

            case Byte is
                when Pkt_End =>
                    if Count > 0 then
                        exit;                           -- Hit the end of the packet, with data to return
                    end if;

                when Pkt_Esc =>
                    Context.Recv(Byte);                 -- Read after Esc byte
                    case Byte is
                        when Pkt_Esc_Esc =>             -- Esc Esc = Esc
                            Byte := Pkt_Esc;
                            Stow_Byte;                  
                        when Pkt_Esc_End =>             -- Esc End = End
                            Byte := Pkt_End;
                            Stow_Byte;              
                        when Pkt_Esc_Rpt =>             
                            if Context.Compress then    -- Esc Rpt = <byte> * <n>
                                Context.Recv(Byte);
                                Context.Recv(Rpt_Count);
                                if Rpt_Count = 0 then
                                    Post_Error('R');    -- Bad Repeat Count
                                else
                                    for R in 1..Rpt_Count loop
                                        Stow_Byte;
                                    end loop;
                                end if;
                            else
                                Stow_Byte;              -- Esc Rpt = Rpt when compression off
                            end if;
                        when others =>                  -- Esc ??? = Error in protocol
                            Post_Error('P');            -- Protocol Error
                            Stow_Byte;                  -- Save byte anyway
                    end case;
                when others =>
                    Stow_Byte;                          -- non-escaped data = data
                end case;
        end loop;
        
        if Truncated then
            Length := Packet'Length;                    -- Returned max buffer length
        else
            Length := Count;                            -- Length of packet returned
        end if;

        if Context.CRC16 then
            if Length <= 2 then
                Post_Error('L');                        -- Too short for CRC-16 packet
            else
                Length := Length - 2;                   -- Reflect true data length

                if not Error then
                    declare
                        CX :        Unsigned_8 := Packet'First + Length;
                        CRC :       CRC16.CRC_Type;     -- Computed CRC-16 value
                        Recv_CRC :  CRC16.CRC_Type;
                    begin
                        CRC16.Init(CRC);
                        for X in Packet'First .. Packet'First + Length - 1 loop
                            CRC16.Update(CRC,Packet(X));    -- Compute CRC-16 
                        end loop;
    
                        Recv_CRC := CRC16.CRC_Make(Packet(CX),Packet(CX+1));

                        if CRC /= Recv_CRC then
                            Post_Error('C');                -- CRC-16 error
                        end if;
                    end;
                end if;
            end if;
        end if;

    end Receive;

    ------------------------------------------------------------------
    -- Return the Reason Code for Error (for debugging)
    ------------------------------------------------------------------
    function Error_Reason(Context : Slip_Context) return Character is
    begin
        return Context.Reason;
    end;

end Slip;
