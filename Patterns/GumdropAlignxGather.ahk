Padding := 8

AlignWidth  := (FieldWidth  / 2) - Padding
AlignHeight := (FieldHeight / 2) - Padding

; gather settings (2,10 recommended, higher values cause significant drift)
MicroStep := 2
MicroHold := 10

MoveBalanced(MicroStep, MicroHold, FwdKey, BackKey, LeftKey, RightKey)
{
    walk(MicroStep, LeftKey)
    Sleep MicroHold

    walk(MicroStep, FwdKey)
    Sleep MicroHold

    walk(MicroStep, RightKey)
    Sleep MicroHold

    walk(MicroStep, BackKey)
    Sleep MicroHold

    walk(MicroStep, RightKey)
    Sleep MicroHold

    walk(MicroStep, FwdKey)
    Sleep MicroHold

    walk(MicroStep, LeftKey)
    Sleep MicroHold

    walk(MicroStep, BackKey)
    Sleep MicroHold
}

; initial alignment
if (index = 1) {

    Switch AltNumber {

        Case 0: ; Center
            Sleep 50

        Case 1: ; Top Left
            walk(AlignHeight, FwdKey)
            walk(AlignWidth,  LeftKey)
            Send "{" RotRight " 3}"

        Case 2: ; Top Right
            walk(AlignHeight, FwdKey)
            walk(AlignWidth,  RightKey)
            Send "{" RotLeft " 3}"

        Case 3: ; Bottom Right
            walk(AlignHeight, BackKey)
            walk(AlignWidth,  RightKey)
            Send "{" RotLeft " 1}"

        Case 4: ; Bottom Left
            walk(AlignHeight, BackKey)
            walk(AlignWidth,  LeftKey)
            Send "{" RotRight " 1}"
    }

    ; camera setup
    Send "{" RotUp " 8}"
    Loop 5
        Send "{" ZoomIn "}"

    Sleep 100
}

; infinite gather loop, 10000 would be 10 seconds
endTime := 99999999999999999

while (A_TickCount < endTime)
{
    MoveBalanced(MicroStep, MicroHold, FwdKey, BackKey, LeftKey, RightKey)
}
