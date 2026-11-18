#include "recomp.h"
#include "funcs.h"

RECOMP_FUNC void func_8420D2BC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8420D2BC: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x8420D2C0: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x8420D2C4: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x8420D2C8: jal         0x8001F3F4
    // 0x8420D2CC: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    func_8001F3F4(rdram, ctx);
        goto after_0;
    // 0x8420D2CC: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    after_0:
    // 0x8420D2D0: addiu       $a0, $zero, 0x10
    ctx->r4 = ADD32(0, 0X10);
    // 0x8420D2D4: jal         0x8001EBE0
    // 0x8420D2D8: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    func_8001EBE0(rdram, ctx);
        goto after_1;
    // 0x8420D2D8: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    after_1:
    // 0x8420D2DC: jal         0x84200130
    // 0x8420D2E0: addiu       $a0, $zero, 0x26
    ctx->r4 = ADD32(0, 0X26);
    func_84200130(rdram, ctx);
        goto after_2;
    // 0x8420D2E0: addiu       $a0, $zero, 0x26
    ctx->r4 = ADD32(0, 0X26);
    after_2:
    // 0x8420D2E4: lh          $a0, 0x0($s0)
    ctx->r4 = MEM_H(ctx->r16, 0X0);
    // 0x8420D2E8: lh          $a1, 0x2($s0)
    ctx->r5 = MEM_H(ctx->r16, 0X2);
    // 0x8420D2EC: or          $a2, $zero, $zero
    ctx->r6 = 0 | 0;
    // 0x8420D2F0: jal         0x8420C7B0
    // 0x8420D2F4: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    func_8420C7B0(rdram, ctx);
        goto after_3;
    // 0x8420D2F4: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    after_3:
    // 0x8420D2F8: jal         0x84200130
    // 0x8420D2FC: addiu       $a0, $zero, 0x20
    ctx->r4 = ADD32(0, 0X20);
    func_84200130(rdram, ctx);
        goto after_4;
    // 0x8420D2FC: addiu       $a0, $zero, 0x20
    ctx->r4 = ADD32(0, 0X20);
    after_4:
    // 0x8420D300: lh          $a0, 0x0($s0)
    ctx->r4 = MEM_H(ctx->r16, 0X0);
    // 0x8420D304: lh          $a1, 0x2($s0)
    ctx->r5 = MEM_H(ctx->r16, 0X2);
    // 0x8420D308: addiu       $a2, $zero, 0x1
    ctx->r6 = ADD32(0, 0X1);
    // 0x8420D30C: jal         0x8420C7B0
    // 0x8420D310: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    func_8420C7B0(rdram, ctx);
        goto after_5;
    // 0x8420D310: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    after_5:
    // 0x8420D314: jal         0x8001F444
    // 0x8420D318: nop

    func_8001F444(rdram, ctx);
        goto after_6;
    // 0x8420D318: nop

    after_6:
    // 0x8420D31C: lui         $v0, 0x8424
    ctx->r2 = S32(RELOC_HI16(255, 0X3E58A) << 16);
    // 0x8420D320: lh          $v0, -0x1A76($v0)
    ctx->r2 = MEM_H(ctx->r2, (int16_t)RELOC_LO16(255, 0X3E58A));
    // 0x8420D324: bltz        $v0, L_8420D35C
    if (SIGNED(ctx->r2) < 0) {
        // 0x8420D328: sll         $t7, $v0, 3
        ctx->r15 = S32(ctx->r2 << 3);
            goto L_8420D35C;
    }
    // 0x8420D328: sll         $t7, $v0, 3
    ctx->r15 = S32(ctx->r2 << 3);
    // 0x8420D32C: lh          $t6, 0x2($s0)
    ctx->r14 = MEM_H(ctx->r16, 0X2);
    // 0x8420D330: lh          $a0, 0x0($s0)
    ctx->r4 = MEM_H(ctx->r16, 0X0);
    // 0x8420D334: subu        $t7, $t7, $v0
    ctx->r15 = SUB32(ctx->r15, ctx->r2);
    // 0x8420D338: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x8420D33C: addu        $a1, $t6, $t7
    ctx->r5 = ADD32(ctx->r14, ctx->r15);
    // 0x8420D340: addiu       $a1, $a1, 0xC
    ctx->r5 = ADD32(ctx->r5, 0XC);
    // 0x8420D344: addiu       $a0, $a0, 0x10
    ctx->r4 = ADD32(ctx->r4, 0X10);
    // 0x8420D348: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x8420D34C: sll         $a1, $a1, 16
    ctx->r5 = S32(ctx->r5 << 16);
    // 0x8420D350: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x8420D354: jal         0x80020928
    // 0x8420D358: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    func_80020928(rdram, ctx);
        goto after_7;
    // 0x8420D358: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    after_7:
L_8420D35C:
    // 0x8420D35C: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x8420D360: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x8420D364: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    // 0x8420D368: jr          $ra
    // 0x8420D36C: nop

    return;
    // 0x8420D36C: nop

;}
RECOMP_FUNC void func_8431F7B0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8431F7B0: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x8431F7B4: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x8431F7B8: lhu         $t6, 0x688($a0)
    ctx->r14 = MEM_HU(ctx->r4, 0X688);
    // 0x8431F7BC: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x8431F7C0: lui         $t8, 0x8439
    ctx->r24 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431F7C4: andi        $t7, $t6, 0x800
    ctx->r15 = ctx->r14 & 0X800;
    // 0x8431F7C8: bne         $t7, $zero, L_8431F7D8
    if (ctx->r15 != 0) {
        // 0x8431F7CC: nop
    
            goto L_8431F7D8;
    }
    // 0x8431F7CC: nop

    // 0x8431F7D0: b           L_8431F878
    // 0x8431F7D4: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
        goto L_8431F878;
    // 0x8431F7D4: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
L_8431F7D8:
    // 0x8431F7D8: lw          $t8, 0x240($t8)
    ctx->r24 = MEM_W(ctx->r24, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431F7DC: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8431F7E0: lw          $v0, 0x24($t8)
    ctx->r2 = MEM_W(ctx->r24, 0X24);
    // 0x8431F7E4: beq         $v0, $zero, L_8431F804
    if (ctx->r2 == 0) {
        // 0x8431F7E8: nop
    
            goto L_8431F804;
    }
    // 0x8431F7E8: nop

    // 0x8431F7EC: beq         $v0, $at, L_8431F828
    if (ctx->r2 == ctx->r1) {
        // 0x8431F7F0: addiu       $at, $zero, 0x2
        ctx->r1 = ADD32(0, 0X2);
            goto L_8431F828;
    }
    // 0x8431F7F0: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x8431F7F4: beq         $v0, $at, L_8431F868
    if (ctx->r2 == ctx->r1) {
        // 0x8431F7F8: nop
    
            goto L_8431F868;
    }
    // 0x8431F7F8: nop

    // 0x8431F7FC: b           L_8431F878
    // 0x8431F800: or          $v0, $a1, $zero
    ctx->r2 = ctx->r5 | 0;
        goto L_8431F878;
    // 0x8431F800: or          $v0, $a1, $zero
    ctx->r2 = ctx->r5 | 0;
L_8431F804:
    // 0x8431F804: jal         0x84302128
    // 0x8431F808: nop

    func_84302128(rdram, ctx);
        goto after_0;
    // 0x8431F808: nop

    after_0:
    // 0x8431F80C: lui         $v0, 0x8439
    ctx->r2 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431F810: lw          $v0, 0x240($v0)
    ctx->r2 = MEM_W(ctx->r2, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431F814: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    // 0x8431F818: lw          $t9, 0x24($v0)
    ctx->r25 = MEM_W(ctx->r2, 0X24);
    // 0x8431F81C: addiu       $t0, $t9, 0x1
    ctx->r8 = ADD32(ctx->r25, 0X1);
    // 0x8431F820: b           L_8431F874
    // 0x8431F824: sw          $t0, 0x24($v0)
    MEM_W(0X24, ctx->r2) = ctx->r8;
        goto L_8431F874;
    // 0x8431F824: sw          $t0, 0x24($v0)
    MEM_W(0X24, ctx->r2) = ctx->r8;
L_8431F828:
    // 0x8431F828: lw          $v0, 0x720($a0)
    ctx->r2 = MEM_W(ctx->r4, 0X720);
    // 0x8431F82C: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    // 0x8431F830: lbu         $v1, 0x0($v0)
    ctx->r3 = MEM_BU(ctx->r2, 0X0);
    // 0x8431F834: andi        $t1, $v1, 0x10
    ctx->r9 = ctx->r3 & 0X10;
    // 0x8431F838: beq         $t1, $zero, L_8431F874
    if (ctx->r9 == 0) {
        // 0x8431F83C: andi        $t2, $v1, 0xFF6F
        ctx->r10 = ctx->r3 & 0XFF6F;
            goto L_8431F874;
    }
    // 0x8431F83C: andi        $t2, $v1, 0xFF6F
    ctx->r10 = ctx->r3 & 0XFF6F;
    // 0x8431F840: sb          $t2, 0x0($v0)
    MEM_B(0X0, ctx->r2) = ctx->r10;
    // 0x8431F844: jal         0x84309328
    // 0x8431F848: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    func_84309328(rdram, ctx);
        goto after_1;
    // 0x8431F848: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    after_1:
    // 0x8431F84C: lui         $v0, 0x8439
    ctx->r2 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431F850: lw          $v0, 0x240($v0)
    ctx->r2 = MEM_W(ctx->r2, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431F854: lw          $a1, 0x1C($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X1C);
    // 0x8431F858: lw          $t3, 0x24($v0)
    ctx->r11 = MEM_W(ctx->r2, 0X24);
    // 0x8431F85C: addiu       $t4, $t3, 0x1
    ctx->r12 = ADD32(ctx->r11, 0X1);
    // 0x8431F860: b           L_8431F874
    // 0x8431F864: sw          $t4, 0x24($v0)
    MEM_W(0X24, ctx->r2) = ctx->r12;
        goto L_8431F874;
    // 0x8431F864: sw          $t4, 0x24($v0)
    MEM_W(0X24, ctx->r2) = ctx->r12;
L_8431F868:
    // 0x8431F868: jal         0x8431F680
    // 0x8431F86C: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    func_8431F680(rdram, ctx);
        goto after_2;
    // 0x8431F86C: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    after_2:
    // 0x8431F870: lw          $a1, 0x1C($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X1C);
L_8431F874:
    // 0x8431F874: or          $v0, $a1, $zero
    ctx->r2 = ctx->r5 | 0;
L_8431F878:
    // 0x8431F878: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x8431F87C: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x8431F880: jr          $ra
    // 0x8431F884: nop

    return;
    // 0x8431F884: nop

;}
RECOMP_FUNC void func_84353098(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84353098: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x8435309C: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x843530A0: sw          $s0, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r16;
    // 0x843530A4: lh          $v0, 0xB2($a0)
    ctx->r2 = MEM_H(ctx->r4, 0XB2);
    // 0x843530A8: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x843530AC: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x843530B0: beq         $v0, $at, L_843530DC
    if (ctx->r2 == ctx->r1) {
        // 0x843530B4: addiu       $at, $zero, 0x2
        ctx->r1 = ADD32(0, 0X2);
            goto L_843530DC;
    }
    // 0x843530B4: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x843530B8: beq         $v0, $at, L_843530EC
    if (ctx->r2 == ctx->r1) {
        // 0x843530BC: addiu       $at, $zero, 0x3
        ctx->r1 = ADD32(0, 0X3);
            goto L_843530EC;
    }
    // 0x843530BC: addiu       $at, $zero, 0x3
    ctx->r1 = ADD32(0, 0X3);
    // 0x843530C0: beq         $v0, $at, L_8435311C
    if (ctx->r2 == ctx->r1) {
        // 0x843530C4: or          $a1, $zero, $zero
        ctx->r5 = 0 | 0;
            goto L_8435311C;
    }
    // 0x843530C4: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x843530C8: addiu       $at, $zero, 0x4
    ctx->r1 = ADD32(0, 0X4);
    // 0x843530CC: beq         $v0, $at, L_8435316C
    if (ctx->r2 == ctx->r1) {
        // 0x843530D0: nop
    
            goto L_8435316C;
    }
    // 0x843530D0: nop

    // 0x843530D4: b           L_84353178
    // 0x843530D8: lh          $v1, 0xB8($a0)
    ctx->r3 = MEM_H(ctx->r4, 0XB8);
        goto L_84353178;
    // 0x843530D8: lh          $v1, 0xB8($a0)
    ctx->r3 = MEM_H(ctx->r4, 0XB8);
L_843530DC:
    // 0x843530DC: jal         0x84352F90
    // 0x843530E0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84352F90(rdram, ctx);
        goto after_0;
    // 0x843530E0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_0:
    // 0x843530E4: b           L_84353178
    // 0x843530E8: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
        goto L_84353178;
    // 0x843530E8: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
L_843530EC:
    // 0x843530EC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x843530F0: jal         0x8140826C
    // 0x843530F4: lh          $a1, 0xA6($s0)
    ctx->r5 = MEM_H(ctx->r16, 0XA6);
    func_8140826C(rdram, ctx);
        goto after_1;
    // 0x843530F4: lh          $a1, 0xA6($s0)
    ctx->r5 = MEM_H(ctx->r16, 0XA6);
    after_1:
    // 0x843530F8: beq         $v0, $zero, L_84353114
    if (ctx->r2 == 0) {
        // 0x843530FC: nop
    
            goto L_84353114;
    }
    // 0x843530FC: nop

    // 0x84353100: jal         0x81408328
    // 0x84353104: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408328(rdram, ctx);
        goto after_2;
    // 0x84353104: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_2:
    // 0x84353108: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8435310C: jal         0x8140BCA8
    // 0x84353110: addiu       $a1, $zero, 0x2
    ctx->r5 = ADD32(0, 0X2);
    func_8140BCA8(rdram, ctx);
        goto after_3;
    // 0x84353110: addiu       $a1, $zero, 0x2
    ctx->r5 = ADD32(0, 0X2);
    after_3:
L_84353114:
    // 0x84353114: b           L_84353178
    // 0x84353118: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
        goto L_84353178;
    // 0x84353118: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
L_8435311C:
    // 0x8435311C: addiu       $t6, $zero, 0x1
    ctx->r14 = ADD32(0, 0X1);
    // 0x84353120: sw          $t6, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r14;
    // 0x84353124: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84353128: addiu       $a2, $zero, 0x3
    ctx->r6 = ADD32(0, 0X3);
    // 0x8435312C: addiu       $a3, $zero, 0x1
    ctx->r7 = ADD32(0, 0X1);
    // 0x84353130: jal         0x814084D8
    // 0x84353134: sw          $zero, 0x14($sp)
    MEM_W(0X14, ctx->r29) = 0;
    func_814084D8(rdram, ctx);
        goto after_4;
    // 0x84353134: sw          $zero, 0x14($sp)
    MEM_W(0X14, ctx->r29) = 0;
    after_4:
    // 0x84353138: jal         0x81409EA0
    // 0x8435313C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81409EA0(rdram, ctx);
        goto after_5;
    // 0x8435313C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_5:
    // 0x84353140: lui         $t7, 0x8141
    ctx->r15 = S32(RELOC_HI16(147, 0XBDAC) << 16);
    // 0x84353144: addiu       $t7, $t7, -0x4254
    ctx->r15 = ADD32(ctx->r15, (int16_t)RELOC_LO16(147, 0XBDAC));
    // 0x84353148: beq         $t7, $zero, L_84353164
    if (ctx->r15 == 0) {
        // 0x8435314C: nop
    
            goto L_84353164;
    }
    // 0x8435314C: nop

    // 0x84353150: lh          $t8, 0xB8($s0)
    ctx->r24 = MEM_H(ctx->r16, 0XB8);
    // 0x84353154: bne         $t8, $zero, L_84353164
    if (ctx->r24 != 0) {
        // 0x84353158: nop
    
            goto L_84353164;
    }
    // 0x84353158: nop

    // 0x8435315C: jal         0x81408A68
    // 0x84353160: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408A68(rdram, ctx);
        goto after_6;
    // 0x84353160: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_6:
L_84353164:
    // 0x84353164: b           L_84353178
    // 0x84353168: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
        goto L_84353178;
    // 0x84353168: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
L_8435316C:
    // 0x8435316C: jal         0x81408150
    // 0x84353170: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408150(rdram, ctx);
        goto after_7;
    // 0x84353170: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_7:
    // 0x84353174: lh          $v1, 0xB8($s0)
    ctx->r3 = MEM_H(ctx->r16, 0XB8);
L_84353178:
    // 0x84353178: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8435317C: beq         $v1, $at, L_843531A4
    if (ctx->r3 == ctx->r1) {
        // 0x84353180: or          $v0, $v1, $zero
        ctx->r2 = ctx->r3 | 0;
            goto L_843531A4;
    }
    // 0x84353180: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
    // 0x84353184: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x84353188: beq         $v1, $at, L_843531D0
    if (ctx->r3 == ctx->r1) {
        // 0x8435318C: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_843531D0;
    }
    // 0x8435318C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84353190: addiu       $at, $zero, 0x3
    ctx->r1 = ADD32(0, 0X3);
    // 0x84353194: beq         $v1, $at, L_84353208
    if (ctx->r3 == ctx->r1) {
        // 0x84353198: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_84353208;
    }
    // 0x84353198: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8435319C: b           L_8435323C
    // 0x843531A0: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
        goto L_8435323C;
    // 0x843531A0: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_843531A4:
    // 0x843531A4: lui         $a1, 0x8435
    ctx->r5 = S32(RELOC_HI16(259, 0X515C8) << 16);
    // 0x843531A8: lui         $a2, 0x8438
    ctx->r6 = S32(RELOC_HI16(259, 0X86390) << 16);
    // 0x843531AC: addiu       $a2, $a2, 0x6390
    ctx->r6 = ADD32(ctx->r6, (int16_t)RELOC_LO16(259, 0X86390));
    // 0x843531B0: addiu       $a1, $a1, 0x15C8
    ctx->r5 = ADD32(ctx->r5, (int16_t)RELOC_LO16(259, 0X515C8));
    // 0x843531B4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x843531B8: jal         0x8432D844
    // 0x843531BC: addiu       $a3, $zero, 0x8
    ctx->r7 = ADD32(0, 0X8);
    func_8432D844(rdram, ctx);
        goto after_8;
    // 0x843531BC: addiu       $a3, $zero, 0x8
    ctx->r7 = ADD32(0, 0X8);
    after_8:
    // 0x843531C0: jal         0x81408A68
    // 0x843531C4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408A68(rdram, ctx);
        goto after_9;
    // 0x843531C4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_9:
    // 0x843531C8: b           L_8435323C
    // 0x843531CC: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
        goto L_8435323C;
    // 0x843531CC: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_843531D0:
    // 0x843531D0: jal         0x81408A78
    // 0x843531D4: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    func_81408A78(rdram, ctx);
        goto after_10;
    // 0x843531D4: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    after_10:
    // 0x843531D8: beq         $v0, $zero, L_84353238
    if (ctx->r2 == 0) {
        // 0x843531DC: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_84353238;
    }
    // 0x843531DC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x843531E0: lui         $a1, 0x8435
    ctx->r5 = S32(RELOC_HI16(259, 0X515C8) << 16);
    // 0x843531E4: lui         $a2, 0x8438
    ctx->r6 = S32(RELOC_HI16(259, 0X86390) << 16);
    // 0x843531E8: addiu       $a2, $a2, 0x6390
    ctx->r6 = ADD32(ctx->r6, (int16_t)RELOC_LO16(259, 0X86390));
    // 0x843531EC: addiu       $a1, $a1, 0x15C8
    ctx->r5 = ADD32(ctx->r5, (int16_t)RELOC_LO16(259, 0X515C8));
    // 0x843531F0: jal         0x8432D844
    // 0x843531F4: addiu       $a3, $zero, 0x4
    ctx->r7 = ADD32(0, 0X4);
    func_8432D844(rdram, ctx);
        goto after_11;
    // 0x843531F4: addiu       $a3, $zero, 0x4
    ctx->r7 = ADD32(0, 0X4);
    after_11:
    // 0x843531F8: jal         0x81408A68
    // 0x843531FC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408A68(rdram, ctx);
        goto after_12;
    // 0x843531FC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_12:
    // 0x84353200: b           L_8435323C
    // 0x84353204: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
        goto L_8435323C;
    // 0x84353204: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_84353208:
    // 0x84353208: jal         0x81408A78
    // 0x8435320C: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    func_81408A78(rdram, ctx);
        goto after_13;
    // 0x8435320C: addiu       $a1, $zero, 0x1
    ctx->r5 = ADD32(0, 0X1);
    after_13:
    // 0x84353210: beq         $v0, $zero, L_84353238
    if (ctx->r2 == 0) {
        // 0x84353214: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_84353238;
    }
    // 0x84353214: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84353218: lui         $a1, 0x8435
    ctx->r5 = S32(RELOC_HI16(259, 0X515C8) << 16);
    // 0x8435321C: lui         $a2, 0x8438
    ctx->r6 = S32(RELOC_HI16(259, 0X86390) << 16);
    // 0x84353220: addiu       $a2, $a2, 0x6390
    ctx->r6 = ADD32(ctx->r6, (int16_t)RELOC_LO16(259, 0X86390));
    // 0x84353224: addiu       $a1, $a1, 0x15C8
    ctx->r5 = ADD32(ctx->r5, (int16_t)RELOC_LO16(259, 0X515C8));
    // 0x84353228: jal         0x8432D844
    // 0x8435322C: addiu       $a3, $zero, 0x4
    ctx->r7 = ADD32(0, 0X4);
    func_8432D844(rdram, ctx);
        goto after_14;
    // 0x8435322C: addiu       $a3, $zero, 0x4
    ctx->r7 = ADD32(0, 0X4);
    after_14:
    // 0x84353230: jal         0x81408A68
    // 0x84353234: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408A68(rdram, ctx);
        goto after_15;
    // 0x84353234: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_15:
L_84353238:
    // 0x84353238: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_8435323C:
    // 0x8435323C: lw          $s0, 0x20($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X20);
    // 0x84353240: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x84353244: jr          $ra
    // 0x84353248: nop

    return;
    // 0x84353248: nop

;}
RECOMP_FUNC void func_8432F9A0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8432F9A0: jr          $ra
    // 0x8432F9A4: nop

    return;
    // 0x8432F9A4: nop

;}
RECOMP_FUNC void func_8434BCD4(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8434BCD4: addiu       $sp, $sp, -0x38
    ctx->r29 = ADD32(ctx->r29, -0X38);
    // 0x8434BCD8: sw          $s1, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r17;
    // 0x8434BCDC: lui         $s1, 0x8141
    ctx->r17 = S32(RELOC_HI16(147, 0XE460) << 16);
    // 0x8434BCE0: addiu       $s1, $s1, -0x1BA0
    ctx->r17 = ADD32(ctx->r17, (int16_t)RELOC_LO16(147, 0XE460));
    // 0x8434BCE4: sw          $ra, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r31;
    // 0x8434BCE8: lui         $a1, 0x8435
    ctx->r5 = S32(RELOC_HI16(259, 0X4B21C) << 16);
    // 0x8434BCEC: addiu       $t6, $zero, 0x1
    ctx->r14 = ADD32(0, 0X1);
    // 0x8434BCF0: addiu       $t7, $zero, 0xC
    ctx->r15 = ADD32(0, 0XC);
    // 0x8434BCF4: addiu       $t8, $zero, 0x1
    ctx->r24 = ADD32(0, 0X1);
    // 0x8434BCF8: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
    // 0x8434BCFC: sw          $t8, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r24;
    // 0x8434BD00: sw          $t7, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r15;
    // 0x8434BD04: sw          $t6, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r14;
    // 0x8434BD08: addiu       $a1, $a1, -0x4DE4
    ctx->r5 = ADD32(ctx->r5, (int16_t)RELOC_LO16(259, 0X4B21C));
    // 0x8434BD0C: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BD10: sw          $zero, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = 0;
    // 0x8434BD14: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    // 0x8434BD18: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    // 0x8434BD1C: jal         0x8432EC28
    // 0x8434BD20: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    func_8432EC28(rdram, ctx);
        goto after_0;
    // 0x8434BD20: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    after_0:
    // 0x8434BD24: lui         $s0, 0x8434
    ctx->r16 = S32(RELOC_HI16(259, 0X416B0) << 16);
    // 0x8434BD28: addiu       $s0, $s0, 0x16B0
    ctx->r16 = ADD32(ctx->r16, (int16_t)RELOC_LO16(259, 0X416B0));
    // 0x8434BD2C: addiu       $t9, $zero, 0x1
    ctx->r25 = ADD32(0, 0X1);
    // 0x8434BD30: addiu       $t0, $zero, 0x9
    ctx->r8 = ADD32(0, 0X9);
    // 0x8434BD34: addiu       $t1, $zero, 0xD
    ctx->r9 = ADD32(0, 0XD);
    // 0x8434BD38: sw          $t1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r9;
    // 0x8434BD3C: sw          $t0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r8;
    // 0x8434BD40: sw          $t9, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r25;
    // 0x8434BD44: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BD48: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    // 0x8434BD4C: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BD50: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BD54: sw          $zero, 0x18($sp)
    MEM_W(0X18, ctx->r29) = 0;
    // 0x8434BD58: jal         0x8432EC28
    // 0x8434BD5C: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_1;
    // 0x8434BD5C: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_1:
    // 0x8434BD60: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x8434BD64: addiu       $t3, $zero, 0x9
    ctx->r11 = ADD32(0, 0X9);
    // 0x8434BD68: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
    // 0x8434BD6C: addiu       $t5, $zero, 0xD
    ctx->r13 = ADD32(0, 0XD);
    // 0x8434BD70: sw          $t5, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r13;
    // 0x8434BD74: sw          $t4, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r12;
    // 0x8434BD78: sw          $t3, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r11;
    // 0x8434BD7C: sw          $t2, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r10;
    // 0x8434BD80: addiu       $a0, $zero, 0x4
    ctx->r4 = ADD32(0, 0X4);
    // 0x8434BD84: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BD88: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BD8C: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BD90: jal         0x8432EC28
    // 0x8434BD94: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_2;
    // 0x8434BD94: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_2:
    // 0x8434BD98: addiu       $t6, $zero, 0x1
    ctx->r14 = ADD32(0, 0X1);
    // 0x8434BD9C: addiu       $t7, $zero, 0x9
    ctx->r15 = ADD32(0, 0X9);
    // 0x8434BDA0: addiu       $t8, $zero, 0x2
    ctx->r24 = ADD32(0, 0X2);
    // 0x8434BDA4: addiu       $t9, $zero, 0xD
    ctx->r25 = ADD32(0, 0XD);
    // 0x8434BDA8: sw          $t9, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r25;
    // 0x8434BDAC: sw          $t8, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r24;
    // 0x8434BDB0: sw          $t7, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r15;
    // 0x8434BDB4: sw          $t6, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r14;
    // 0x8434BDB8: addiu       $a0, $zero, 0x8
    ctx->r4 = ADD32(0, 0X8);
    // 0x8434BDBC: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BDC0: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BDC4: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BDC8: jal         0x8432EC28
    // 0x8434BDCC: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_3;
    // 0x8434BDCC: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_3:
    // 0x8434BDD0: addiu       $t0, $zero, 0x1
    ctx->r8 = ADD32(0, 0X1);
    // 0x8434BDD4: addiu       $t1, $zero, 0x9
    ctx->r9 = ADD32(0, 0X9);
    // 0x8434BDD8: addiu       $t2, $zero, 0xD
    ctx->r10 = ADD32(0, 0XD);
    // 0x8434BDDC: sw          $t2, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r10;
    // 0x8434BDE0: sw          $t1, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r9;
    // 0x8434BDE4: sw          $t0, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r8;
    // 0x8434BDE8: addiu       $a0, $zero, 0xC
    ctx->r4 = ADD32(0, 0XC);
    // 0x8434BDEC: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BDF0: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BDF4: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BDF8: sw          $zero, 0x18($sp)
    MEM_W(0X18, ctx->r29) = 0;
    // 0x8434BDFC: jal         0x8432EC28
    // 0x8434BE00: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_4;
    // 0x8434BE00: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_4:
    // 0x8434BE04: addiu       $t3, $zero, 0x1
    ctx->r11 = ADD32(0, 0X1);
    // 0x8434BE08: addiu       $t4, $zero, 0x9
    ctx->r12 = ADD32(0, 0X9);
    // 0x8434BE0C: addiu       $t5, $zero, 0x1
    ctx->r13 = ADD32(0, 0X1);
    // 0x8434BE10: addiu       $t6, $zero, 0xD
    ctx->r14 = ADD32(0, 0XD);
    // 0x8434BE14: sw          $t6, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r14;
    // 0x8434BE18: sw          $t5, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r13;
    // 0x8434BE1C: sw          $t4, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r12;
    // 0x8434BE20: sw          $t3, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r11;
    // 0x8434BE24: addiu       $a0, $zero, 0x10
    ctx->r4 = ADD32(0, 0X10);
    // 0x8434BE28: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BE2C: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BE30: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BE34: jal         0x8432EC28
    // 0x8434BE38: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_5;
    // 0x8434BE38: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_5:
    // 0x8434BE3C: addiu       $t7, $zero, 0x1
    ctx->r15 = ADD32(0, 0X1);
    // 0x8434BE40: addiu       $t8, $zero, 0x9
    ctx->r24 = ADD32(0, 0X9);
    // 0x8434BE44: addiu       $t9, $zero, 0x2
    ctx->r25 = ADD32(0, 0X2);
    // 0x8434BE48: addiu       $t0, $zero, 0xD
    ctx->r8 = ADD32(0, 0XD);
    // 0x8434BE4C: sw          $t0, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r8;
    // 0x8434BE50: sw          $t9, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r25;
    // 0x8434BE54: sw          $t8, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r24;
    // 0x8434BE58: sw          $t7, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r15;
    // 0x8434BE5C: addiu       $a0, $zero, 0x14
    ctx->r4 = ADD32(0, 0X14);
    // 0x8434BE60: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BE64: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BE68: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BE6C: jal         0x8432EC28
    // 0x8434BE70: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_6;
    // 0x8434BE70: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_6:
    // 0x8434BE74: addiu       $t1, $zero, 0x1
    ctx->r9 = ADD32(0, 0X1);
    // 0x8434BE78: addiu       $t2, $zero, 0x9
    ctx->r10 = ADD32(0, 0X9);
    // 0x8434BE7C: addiu       $t3, $zero, 0xD
    ctx->r11 = ADD32(0, 0XD);
    // 0x8434BE80: sw          $t3, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r11;
    // 0x8434BE84: sw          $t2, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r10;
    // 0x8434BE88: sw          $t1, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r9;
    // 0x8434BE8C: addiu       $a0, $zero, 0x18
    ctx->r4 = ADD32(0, 0X18);
    // 0x8434BE90: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BE94: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BE98: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BE9C: sw          $zero, 0x18($sp)
    MEM_W(0X18, ctx->r29) = 0;
    // 0x8434BEA0: jal         0x8432EC28
    // 0x8434BEA4: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_7;
    // 0x8434BEA4: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_7:
    // 0x8434BEA8: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
    // 0x8434BEAC: addiu       $t5, $zero, 0x9
    ctx->r13 = ADD32(0, 0X9);
    // 0x8434BEB0: addiu       $t6, $zero, 0x1
    ctx->r14 = ADD32(0, 0X1);
    // 0x8434BEB4: addiu       $t7, $zero, 0xD
    ctx->r15 = ADD32(0, 0XD);
    // 0x8434BEB8: sw          $t7, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r15;
    // 0x8434BEBC: sw          $t6, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r14;
    // 0x8434BEC0: sw          $t5, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r13;
    // 0x8434BEC4: sw          $t4, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r12;
    // 0x8434BEC8: addiu       $a0, $zero, 0x1C
    ctx->r4 = ADD32(0, 0X1C);
    // 0x8434BECC: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BED0: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BED4: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BED8: jal         0x8432EC28
    // 0x8434BEDC: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_8;
    // 0x8434BEDC: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_8:
    // 0x8434BEE0: addiu       $t8, $zero, 0x1
    ctx->r24 = ADD32(0, 0X1);
    // 0x8434BEE4: addiu       $t9, $zero, 0x9
    ctx->r25 = ADD32(0, 0X9);
    // 0x8434BEE8: addiu       $t0, $zero, 0x2
    ctx->r8 = ADD32(0, 0X2);
    // 0x8434BEEC: addiu       $t1, $zero, 0xD
    ctx->r9 = ADD32(0, 0XD);
    // 0x8434BEF0: sw          $t1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r9;
    // 0x8434BEF4: sw          $t0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r8;
    // 0x8434BEF8: sw          $t9, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r25;
    // 0x8434BEFC: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    // 0x8434BF00: addiu       $a0, $zero, 0x20
    ctx->r4 = ADD32(0, 0X20);
    // 0x8434BF04: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x8434BF08: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x8434BF0C: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
    // 0x8434BF10: jal         0x8432EC28
    // 0x8434BF14: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    func_8432EC28(rdram, ctx);
        goto after_9;
    // 0x8434BF14: sw          $zero, 0x20($sp)
    MEM_W(0X20, ctx->r29) = 0;
    after_9:
    // 0x8434BF18: lw          $ra, 0x34($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X34);
    // 0x8434BF1C: lw          $s0, 0x2C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X2C);
    // 0x8434BF20: lw          $s1, 0x30($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X30);
    // 0x8434BF24: jr          $ra
    // 0x8434BF28: addiu       $sp, $sp, 0x38
    ctx->r29 = ADD32(ctx->r29, 0X38);
    return;
    // 0x8434BF28: addiu       $sp, $sp, 0x38
    ctx->r29 = ADD32(ctx->r29, 0X38);
;}
RECOMP_FUNC void func_8434C29C(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8434C29C: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x8434C2A0: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x8434C2A4: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x8434C2A8: lh          $v0, 0xB2($a0)
    ctx->r2 = MEM_H(ctx->r4, 0XB2);
    // 0x8434C2AC: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8434C2B0: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x8434C2B4: beq         $v0, $at, L_8434C2CC
    if (ctx->r2 == ctx->r1) {
        // 0x8434C2B8: addiu       $at, $zero, 0x2
        ctx->r1 = ADD32(0, 0X2);
            goto L_8434C2CC;
    }
    // 0x8434C2B8: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x8434C2BC: beq         $v0, $at, L_8434C2DC
    if (ctx->r2 == ctx->r1) {
        // 0x8434C2C0: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_8434C2DC;
    }
    // 0x8434C2C0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8434C2C4: b           L_8434C2F8
    // 0x8434C2C8: nop

        goto L_8434C2F8;
    // 0x8434C2C8: nop

L_8434C2CC:
    // 0x8434C2CC: jal         0x8434C214
    // 0x8434C2D0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8434C214(rdram, ctx);
        goto after_0;
    // 0x8434C2D0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_0:
    // 0x8434C2D4: b           L_8434C2F8
    // 0x8434C2D8: nop

        goto L_8434C2F8;
    // 0x8434C2D8: nop

L_8434C2DC:
    // 0x8434C2DC: addiu       $a1, $zero, 0xFF
    ctx->r5 = ADD32(0, 0XFF);
    // 0x8434C2E0: jal         0x8140BC2C
    // 0x8434C2E4: addiu       $a2, $zero, 0x8
    ctx->r6 = ADD32(0, 0X8);
    func_8140BC2C(rdram, ctx);
        goto after_1;
    // 0x8434C2E4: addiu       $a2, $zero, 0x8
    ctx->r6 = ADD32(0, 0X8);
    after_1:
    // 0x8434C2E8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8434C2EC: addiu       $a1, $zero, 0xC8
    ctx->r5 = ADD32(0, 0XC8);
    // 0x8434C2F0: jal         0x8140BF60
    // 0x8434C2F4: addiu       $a2, $zero, 0x6
    ctx->r6 = ADD32(0, 0X6);
    func_8140BF60(rdram, ctx);
        goto after_2;
    // 0x8434C2F4: addiu       $a2, $zero, 0x6
    ctx->r6 = ADD32(0, 0X6);
    after_2:
L_8434C2F8:
    // 0x8434C2F8: jal         0x8432D424
    // 0x8434C2FC: addiu       $a0, $sp, 0x26
    ctx->r4 = ADD32(ctx->r29, 0X26);
    func_8432D424(rdram, ctx);
        goto after_3;
    // 0x8434C2FC: addiu       $a0, $sp, 0x26
    ctx->r4 = ADD32(ctx->r29, 0X26);
    after_3:
    // 0x8434C300: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8434C304: jal         0x8140A2B8
    // 0x8434C308: lh          $a1, 0x26($sp)
    ctx->r5 = MEM_H(ctx->r29, 0X26);
    func_8140A2B8(rdram, ctx);
        goto after_4;
    // 0x8434C308: lh          $a1, 0x26($sp)
    ctx->r5 = MEM_H(ctx->r29, 0X26);
    after_4:
    // 0x8434C30C: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x8434C310: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x8434C314: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x8434C318: jr          $ra
    // 0x8434C31C: nop

    return;
    // 0x8434C31C: nop

;}
RECOMP_FUNC void func_88602F04(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88602F04: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x88602F08: sw          $s1, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r17;
    // 0x88602F0C: or          $a3, $a0, $zero
    ctx->r7 = ctx->r4 | 0;
    // 0x88602F10: sll         $t8, $a2, 2
    ctx->r24 = S32(ctx->r6 << 2);
    // 0x88602F14: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x88602F18: sw          $s0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r16;
    // 0x88602F1C: sw          $a1, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r5;
    // 0x88602F20: addu        $s1, $a3, $t8
    ctx->r17 = ADD32(ctx->r7, ctx->r24);
    // 0x88602F24: lw          $t9, 0x4C($s1)
    ctx->r25 = MEM_W(ctx->r17, 0X4C);
    // 0x88602F28: sll         $t7, $a1, 2
    ctx->r15 = S32(ctx->r5 << 2);
    // 0x88602F2C: addu        $s0, $a0, $t7
    ctx->r16 = ADD32(ctx->r4, ctx->r15);
    // 0x88602F30: lwl         $t1, 0x10($t9)
    ctx->r9 = do_lwl(rdram, ctx->r9, ctx->r25, 0X10);
    // 0x88602F34: lwr         $t1, 0x13($t9)
    ctx->r9 = do_lwr(rdram, ctx->r9, ctx->r25, 0X13);
    // 0x88602F38: lw          $a0, 0x4C($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X4C);
    // 0x88602F3C: swl         $t1, 0x4($sp)
    do_swl(rdram, 0X4, ctx->r29, ctx->r9);
    // 0x88602F40: swr         $t1, 0x7($sp)
    do_swr(rdram, 0X7, ctx->r29, ctx->r9);
    // 0x88602F44: jal         0x88601AB0
    // 0x88602F48: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    func_88601AB0(rdram, ctx);
        goto after_0;
    // 0x88602F48: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    after_0:
    // 0x88602F4C: lw          $t2, 0x4C($s0)
    ctx->r10 = MEM_W(ctx->r16, 0X4C);
    // 0x88602F50: lw          $a0, 0x4C($s1)
    ctx->r4 = MEM_W(ctx->r17, 0X4C);
    // 0x88602F54: lwl         $t4, 0x10($t2)
    ctx->r12 = do_lwl(rdram, ctx->r12, ctx->r10, 0X10);
    // 0x88602F58: lwr         $t4, 0x13($t2)
    ctx->r12 = do_lwr(rdram, ctx->r12, ctx->r10, 0X13);
    // 0x88602F5C: swl         $t4, 0x4($sp)
    do_swl(rdram, 0X4, ctx->r29, ctx->r12);
    // 0x88602F60: swr         $t4, 0x7($sp)
    do_swr(rdram, 0X7, ctx->r29, ctx->r12);
    // 0x88602F64: jal         0x88601AB0
    // 0x88602F68: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    func_88601AB0(rdram, ctx);
        goto after_1;
    // 0x88602F68: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    after_1:
    // 0x88602F6C: lw          $t5, 0x6C($s1)
    ctx->r13 = MEM_W(ctx->r17, 0X6C);
    // 0x88602F70: lw          $a0, 0x6C($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X6C);
    // 0x88602F74: lwl         $t7, 0x10($t5)
    ctx->r15 = do_lwl(rdram, ctx->r15, ctx->r13, 0X10);
    // 0x88602F78: lwr         $t7, 0x13($t5)
    ctx->r15 = do_lwr(rdram, ctx->r15, ctx->r13, 0X13);
    // 0x88602F7C: swl         $t7, 0x4($sp)
    do_swl(rdram, 0X4, ctx->r29, ctx->r15);
    // 0x88602F80: swr         $t7, 0x7($sp)
    do_swr(rdram, 0X7, ctx->r29, ctx->r15);
    // 0x88602F84: jal         0x88601AB0
    // 0x88602F88: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    func_88601AB0(rdram, ctx);
        goto after_2;
    // 0x88602F88: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    after_2:
    // 0x88602F8C: lw          $t8, 0x6C($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X6C);
    // 0x88602F90: lw          $a0, 0x6C($s1)
    ctx->r4 = MEM_W(ctx->r17, 0X6C);
    // 0x88602F94: lwl         $t0, 0x10($t8)
    ctx->r8 = do_lwl(rdram, ctx->r8, ctx->r24, 0X10);
    // 0x88602F98: lwr         $t0, 0x13($t8)
    ctx->r8 = do_lwr(rdram, ctx->r8, ctx->r24, 0X13);
    // 0x88602F9C: swl         $t0, 0x4($sp)
    do_swl(rdram, 0X4, ctx->r29, ctx->r8);
    // 0x88602FA0: swr         $t0, 0x7($sp)
    do_swr(rdram, 0X7, ctx->r29, ctx->r8);
    // 0x88602FA4: jal         0x88601AB0
    // 0x88602FA8: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    func_88601AB0(rdram, ctx);
        goto after_3;
    // 0x88602FA8: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    after_3:
    // 0x88602FAC: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x88602FB0: lw          $s0, 0x14($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X14);
    // 0x88602FB4: lw          $s1, 0x18($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X18);
    // 0x88602FB8: jr          $ra
    // 0x88602FBC: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    return;
    // 0x88602FBC: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
;}
RECOMP_FUNC void func_84342980(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84342980: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8C4DC) << 16);
    // 0x84342984: lwc1        $f4, -0x3B24($at)
    ctx->f4.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8C4DC));
    // 0x84342988: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x8434298C: mtc1        $zero, $f0
    ctx->f0.u32l = 0;
    // 0x84342990: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x84342994: sw          $a0, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r4;
    // 0x84342998: swc1        $f4, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f4.u32l;
    // 0x8434299C: lw          $a0, 0x10($a0)
    ctx->r4 = MEM_W(ctx->r4, 0X10);
    // 0x843429A0: swc1        $f0, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->f0.u32l;
    // 0x843429A4: jal         0x843081BC
    // 0x843429A8: swc1        $f0, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->f0.u32l;
    func_843081BC(rdram, ctx);
        goto after_0;
    // 0x843429A8: swc1        $f0, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->f0.u32l;
    after_0:
    // 0x843429AC: addiu       $t7, $v0, -0x4
    ctx->r15 = ADD32(ctx->r2, -0X4);
    // 0x843429B0: sltiu       $at, $t7, 0x8E
    ctx->r1 = ctx->r15 < 0X8E ? 1 : 0;
    // 0x843429B4: lwc1        $f0, 0x24($sp)
    ctx->f0.u32l = MEM_W(ctx->r29, 0X24);
    // 0x843429B8: beq         $at, $zero, L_84342C04
    if (ctx->r1 == 0) {
        // 0x843429BC: lwc1        $f2, 0x20($sp)
        ctx->f2.u32l = MEM_W(ctx->r29, 0X20);
            goto L_84342C04;
    }
    // 0x843429BC: lwc1        $f2, 0x20($sp)
    ctx->f2.u32l = MEM_W(ctx->r29, 0X20);
    // 0x843429C0: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x843429C4: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8C4E0) << 16);
    // 0x843429C8: addu        $at, $at, $t7
    gpr jr_addend_843429D0 = ctx->r15;
    ctx->r1 = ADD32(ctx->r1, ctx->r15);
    // 0x843429CC: lw          $t7, -0x3B20($at)
    ctx->r15 = ADD32(ctx->r1, (int16_t)RELOC_LO16(259, 0X8C4E0));
    // 0x843429D0: jr          $t7
    // 0x843429D4: nop

    switch (jr_addend_843429D0 >> 2) {
        case 0: goto L_843429D8; break;
        case 1: goto L_84342C04; break;
        case 2: goto L_84342C04; break;
        case 3: goto L_84342C04; break;
        case 4: goto L_84342C04; break;
        case 5: goto L_84342C04; break;
        case 6: goto L_84342C04; break;
        case 7: goto L_84342C04; break;
        case 8: goto L_84342C04; break;
        case 9: goto L_84342C04; break;
        case 10: goto L_84342C04; break;
        case 11: goto L_843429E8; break;
        case 12: goto L_84342C04; break;
        case 13: goto L_84342C04; break;
        case 14: goto L_84342C04; break;
        case 15: goto L_84342C04; break;
        case 16: goto L_84342C04; break;
        case 17: goto L_84342C04; break;
        case 18: goto L_843429F8; break;
        case 19: goto L_84342C04; break;
        case 20: goto L_84342C04; break;
        case 21: goto L_84342C04; break;
        case 22: goto L_84342C04; break;
        case 23: goto L_84342C04; break;
        case 24: goto L_84342C04; break;
        case 25: goto L_84342C04; break;
        case 26: goto L_84342C04; break;
        case 27: goto L_84342A08; break;
        case 28: goto L_84342C04; break;
        case 29: goto L_84342C04; break;
        case 30: goto L_84342A18; break;
        case 31: goto L_84342C04; break;
        case 32: goto L_84342A28; break;
        case 33: goto L_84342C04; break;
        case 34: goto L_84342C04; break;
        case 35: goto L_84342C04; break;
        case 36: goto L_84342C04; break;
        case 37: goto L_84342C04; break;
        case 38: goto L_84342A38; break;
        case 39: goto L_84342C04; break;
        case 40: goto L_84342C04; break;
        case 41: goto L_84342A48; break;
        case 42: goto L_84342C04; break;
        case 43: goto L_84342C04; break;
        case 44: goto L_84342C04; break;
        case 45: goto L_84342C04; break;
        case 46: goto L_84342C04; break;
        case 47: goto L_84342C04; break;
        case 48: goto L_84342C04; break;
        case 49: goto L_84342C04; break;
        case 50: goto L_84342C04; break;
        case 51: goto L_84342C04; break;
        case 52: goto L_84342C04; break;
        case 53: goto L_84342A60; break;
        case 54: goto L_84342C04; break;
        case 55: goto L_84342C04; break;
        case 56: goto L_84342C04; break;
        case 57: goto L_84342C04; break;
        case 58: goto L_84342C04; break;
        case 59: goto L_84342C04; break;
        case 60: goto L_84342C04; break;
        case 61: goto L_84342A70; break;
        case 62: goto L_84342C04; break;
        case 63: goto L_84342C04; break;
        case 64: goto L_84342C04; break;
        case 65: goto L_84342C04; break;
        case 66: goto L_84342C04; break;
        case 67: goto L_84342C04; break;
        case 68: goto L_84342C04; break;
        case 69: goto L_84342C04; break;
        case 70: goto L_84342A80; break;
        case 71: goto L_84342C04; break;
        case 72: goto L_84342A90; break;
        case 73: goto L_84342C04; break;
        case 74: goto L_84342C04; break;
        case 75: goto L_84342AA0; break;
        case 76: goto L_84342AB8; break;
        case 77: goto L_84342C04; break;
        case 78: goto L_84342C04; break;
        case 79: goto L_84342C04; break;
        case 80: goto L_84342AD0; break;
        case 81: goto L_84342AE0; break;
        case 82: goto L_84342C04; break;
        case 83: goto L_84342C04; break;
        case 84: goto L_84342C04; break;
        case 85: goto L_84342C04; break;
        case 86: goto L_84342AF8; break;
        case 87: goto L_84342B10; break;
        case 88: goto L_84342C04; break;
        case 89: goto L_84342C04; break;
        case 90: goto L_84342B20; break;
        case 91: goto L_84342C04; break;
        case 92: goto L_84342C04; break;
        case 93: goto L_84342B30; break;
        case 94: goto L_84342C04; break;
        case 95: goto L_84342C04; break;
        case 96: goto L_84342C04; break;
        case 97: goto L_84342C04; break;
        case 98: goto L_84342C04; break;
        case 99: goto L_84342C04; break;
        case 100: goto L_84342C04; break;
        case 101: goto L_84342C04; break;
        case 102: goto L_84342C04; break;
        case 103: goto L_84342C04; break;
        case 104: goto L_84342C04; break;
        case 105: goto L_84342C04; break;
        case 106: goto L_84342C04; break;
        case 107: goto L_84342C04; break;
        case 108: goto L_84342C04; break;
        case 109: goto L_84342C04; break;
        case 110: goto L_84342C04; break;
        case 111: goto L_84342B40; break;
        case 112: goto L_84342C04; break;
        case 113: goto L_84342C04; break;
        case 114: goto L_84342C04; break;
        case 115: goto L_84342C04; break;
        case 116: goto L_84342C04; break;
        case 117: goto L_84342C04; break;
        case 118: goto L_84342C04; break;
        case 119: goto L_84342C04; break;
        case 120: goto L_84342C04; break;
        case 121: goto L_84342C04; break;
        case 122: goto L_84342C04; break;
        case 123: goto L_84342B50; break;
        case 124: goto L_84342B60; break;
        case 125: goto L_84342C04; break;
        case 126: goto L_84342B70; break;
        case 127: goto L_84342B88; break;
        case 128: goto L_84342C04; break;
        case 129: goto L_84342C04; break;
        case 130: goto L_84342BA0; break;
        case 131: goto L_84342C04; break;
        case 132: goto L_84342BB0; break;
        case 133: goto L_84342C04; break;
        case 134: goto L_84342BC0; break;
        case 135: goto L_84342C04; break;
        case 136: goto L_84342BD0; break;
        case 137: goto L_84342C04; break;
        case 138: goto L_84342BE8; break;
        case 139: goto L_84342C04; break;
        case 140: goto L_84342C04; break;
        case 141: goto L_84342BF8; break;
        default: switch_error(__func__, 0x843429D0, 0x8438C4E0);
    }
    // 0x843429D4: nop

L_843429D8:
    // 0x843429D8: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x843429DC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x843429E0: b           L_84342C08
    // 0x843429E4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x843429E4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_843429E8:
    // 0x843429E8: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x843429EC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x843429F0: b           L_84342C08
    // 0x843429F4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x843429F4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_843429F8:
    // 0x843429F8: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x843429FC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A00: b           L_84342C08
    // 0x84342A04: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A04: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A08:
    // 0x84342A08: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342A0C: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A10: b           L_84342C08
    // 0x84342A14: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A14: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A18:
    // 0x84342A18: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342A1C: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A20: b           L_84342C08
    // 0x84342A24: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A24: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A28:
    // 0x84342A28: lui         $at, 0x4170
    ctx->r1 = S32(0X4170 << 16);
    // 0x84342A2C: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342A30: b           L_84342C04
    // 0x84342A34: mov.s       $f0, $f2
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 2);
    ctx->f0.fl = ctx->f2.fl;
        goto L_84342C04;
    // 0x84342A34: mov.s       $f0, $f2
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 2);
    ctx->f0.fl = ctx->f2.fl;
L_84342A38:
    // 0x84342A38: lui         $at, 0x4140
    ctx->r1 = S32(0X4140 << 16);
    // 0x84342A3C: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342A40: b           L_84342C08
    // 0x84342A44: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A44: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A48:
    // 0x84342A48: lui         $at, 0x41A0
    ctx->r1 = S32(0X41A0 << 16);
    // 0x84342A4C: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342A50: lui         $at, 0xC170
    ctx->r1 = S32(0XC170 << 16);
    // 0x84342A54: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A58: b           L_84342C08
    // 0x84342A5C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A5C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A60:
    // 0x84342A60: lui         $at, 0x4120
    ctx->r1 = S32(0X4120 << 16);
    // 0x84342A64: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A68: b           L_84342C08
    // 0x84342A6C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A6C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A70:
    // 0x84342A70: lui         $at, 0x4100
    ctx->r1 = S32(0X4100 << 16);
    // 0x84342A74: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A78: b           L_84342C08
    // 0x84342A7C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A7C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A80:
    // 0x84342A80: lui         $at, 0x4120
    ctx->r1 = S32(0X4120 << 16);
    // 0x84342A84: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A88: b           L_84342C08
    // 0x84342A8C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A8C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342A90:
    // 0x84342A90: lui         $at, 0x4000
    ctx->r1 = S32(0X4000 << 16);
    // 0x84342A94: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342A98: b           L_84342C08
    // 0x84342A9C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342A9C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342AA0:
    // 0x84342AA0: lui         $at, 0x4100
    ctx->r1 = S32(0X4100 << 16);
    // 0x84342AA4: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342AA8: lui         $at, 0x40E0
    ctx->r1 = S32(0X40E0 << 16);
    // 0x84342AAC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342AB0: b           L_84342C08
    // 0x84342AB4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342AB4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342AB8:
    // 0x84342AB8: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342ABC: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342AC0: lui         $at, 0x40E0
    ctx->r1 = S32(0X40E0 << 16);
    // 0x84342AC4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342AC8: b           L_84342C08
    // 0x84342ACC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342ACC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342AD0:
    // 0x84342AD0: lui         $at, 0x41A0
    ctx->r1 = S32(0X41A0 << 16);
    // 0x84342AD4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342AD8: b           L_84342C04
    // 0x84342ADC: mov.s       $f2, $f0
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    ctx->f2.fl = ctx->f0.fl;
        goto L_84342C04;
    // 0x84342ADC: mov.s       $f2, $f0
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    ctx->f2.fl = ctx->f0.fl;
L_84342AE0:
    // 0x84342AE0: lui         $at, 0x41A0
    ctx->r1 = S32(0X41A0 << 16);
    // 0x84342AE4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342AE8: lui         $at, 0x41C8
    ctx->r1 = S32(0X41C8 << 16);
    // 0x84342AEC: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342AF0: b           L_84342C08
    // 0x84342AF4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342AF4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342AF8:
    // 0x84342AF8: lui         $at, 0xC170
    ctx->r1 = S32(0XC170 << 16);
    // 0x84342AFC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B00: lui         $at, 0x40E0
    ctx->r1 = S32(0X40E0 << 16);
    // 0x84342B04: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342B08: b           L_84342C08
    // 0x84342B0C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B0C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B10:
    // 0x84342B10: lui         $at, 0xC120
    ctx->r1 = S32(0XC120 << 16);
    // 0x84342B14: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B18: b           L_84342C08
    // 0x84342B1C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B1C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B20:
    // 0x84342B20: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342B24: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B28: b           L_84342C08
    // 0x84342B2C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B2C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B30:
    // 0x84342B30: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342B34: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B38: b           L_84342C08
    // 0x84342B3C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B3C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B40:
    // 0x84342B40: lui         $at, 0x4140
    ctx->r1 = S32(0X4140 << 16);
    // 0x84342B44: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B48: b           L_84342C08
    // 0x84342B4C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B4C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B50:
    // 0x84342B50: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342B54: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B58: b           L_84342C08
    // 0x84342B5C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B5C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B60:
    // 0x84342B60: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342B64: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B68: b           L_84342C08
    // 0x84342B6C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342B6C: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342B70:
    // 0x84342B70: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8C718) << 16);
    // 0x84342B74: lwc1        $f6, -0x38E8($at)
    ctx->f6.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8C718));
    // 0x84342B78: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342B7C: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342B80: b           L_84342C04
    // 0x84342B84: swc1        $f6, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f6.u32l;
        goto L_84342C04;
    // 0x84342B84: swc1        $f6, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f6.u32l;
L_84342B88:
    // 0x84342B88: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8C71C) << 16);
    // 0x84342B8C: lwc1        $f8, -0x38E4($at)
    ctx->f8.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8C71C));
    // 0x84342B90: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
    // 0x84342B94: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342B98: b           L_84342C04
    // 0x84342B9C: swc1        $f8, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f8.u32l;
        goto L_84342C04;
    // 0x84342B9C: swc1        $f8, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f8.u32l;
L_84342BA0:
    // 0x84342BA0: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342BA4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342BA8: b           L_84342C08
    // 0x84342BAC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342BAC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342BB0:
    // 0x84342BB0: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342BB4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342BB8: b           L_84342C08
    // 0x84342BBC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342BBC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342BC0:
    // 0x84342BC0: lui         $at, 0x4170
    ctx->r1 = S32(0X4170 << 16);
    // 0x84342BC4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342BC8: b           L_84342C08
    // 0x84342BCC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342BCC: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342BD0:
    // 0x84342BD0: lui         $at, 0x4140
    ctx->r1 = S32(0X4140 << 16);
    // 0x84342BD4: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342BD8: lui         $at, 0x4120
    ctx->r1 = S32(0X4120 << 16);
    // 0x84342BDC: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x84342BE0: b           L_84342C08
    // 0x84342BE4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342BE4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342BE8:
    // 0x84342BE8: lui         $at, 0x4120
    ctx->r1 = S32(0X4120 << 16);
    // 0x84342BEC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342BF0: b           L_84342C08
    // 0x84342BF4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
        goto L_84342C08;
    // 0x84342BF4: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342BF8:
    // 0x84342BF8: lui         $at, 0x4040
    ctx->r1 = S32(0X4040 << 16);
    // 0x84342BFC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x84342C00: nop

L_84342C04:
    // 0x84342C04: lui         $at, 0x40A0
    ctx->r1 = S32(0X40A0 << 16);
L_84342C08:
    // 0x84342C08: mtc1        $at, $f10
    ctx->f10.u32l = ctx->r1;
    // 0x84342C0C: lw          $a0, 0x28($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X28);
    // 0x84342C10: swc1        $f2, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->f2.u32l;
    // 0x84342C14: add.s       $f16, $f0, $f10
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f0.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f16.fl = ctx->f0.fl + ctx->f10.fl;
    // 0x84342C18: mfc1        $a1, $f16
    ctx->r5 = (int32_t)ctx->f16.u32l;
    // 0x84342C1C: jal         0x81408ED0
    // 0x84342C20: nop

    func_81408ED0(rdram, ctx);
        goto after_1;
    // 0x84342C20: nop

    after_1:
    // 0x84342C24: lwc1        $f2, 0x20($sp)
    ctx->f2.u32l = MEM_W(ctx->r29, 0X20);
    // 0x84342C28: lw          $a0, 0x28($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X28);
    // 0x84342C2C: mfc1        $a1, $f2
    ctx->r5 = (int32_t)ctx->f2.u32l;
    // 0x84342C30: jal         0x81408E90
    // 0x84342C34: nop

    func_81408E90(rdram, ctx);
        goto after_2;
    // 0x84342C34: nop

    after_2:
    // 0x84342C38: lw          $a0, 0x28($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X28);
    // 0x84342C3C: jal         0x8140B938
    // 0x84342C40: lw          $a1, 0x1C($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X1C);
    func_8140B938(rdram, ctx);
        goto after_3;
    // 0x84342C40: lw          $a1, 0x1C($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X1C);
    after_3:
    // 0x84342C44: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x84342C48: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x84342C4C: jr          $ra
    // 0x84342C50: nop

    return;
    // 0x84342C50: nop

;}
RECOMP_FUNC void func_84351BCC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84351BCC: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x84351BD0: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x84351BD4: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x84351BD8: lh          $t6, 0xB2($a0)
    ctx->r14 = MEM_H(ctx->r4, 0XB2);
    // 0x84351BDC: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x84351BE0: addiu       $t7, $t6, -0x1
    ctx->r15 = ADD32(ctx->r14, -0X1);
    // 0x84351BE4: sltiu       $at, $t7, 0x6
    ctx->r1 = ctx->r15 < 0X6 ? 1 : 0;
    // 0x84351BE8: beq         $at, $zero, L_84351CA8
    if (ctx->r1 == 0) {
        // 0x84351BEC: sll         $t7, $t7, 2
        ctx->r15 = S32(ctx->r15 << 2);
            goto L_84351CA8;
    }
    // 0x84351BEC: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x84351BF0: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8D054) << 16);
    // 0x84351BF4: addu        $at, $at, $t7
    gpr jr_addend_84351BFC = ctx->r15;
    ctx->r1 = ADD32(ctx->r1, ctx->r15);
    // 0x84351BF8: lw          $t7, -0x2FAC($at)
    ctx->r15 = ADD32(ctx->r1, (int16_t)RELOC_LO16(259, 0X8D054));
    // 0x84351BFC: jr          $t7
    // 0x84351C00: nop

    switch (jr_addend_84351BFC >> 2) {
        case 0: goto L_84351C04; break;
        case 1: goto L_84351C14; break;
        case 2: goto L_84351C34; break;
        case 3: goto L_84351C68; break;
        case 4: goto L_84351C7C; break;
        case 5: goto L_84351CA0; break;
        default: switch_error(__func__, 0x84351BFC, 0x8438D054);
    }
    // 0x84351C00: nop

L_84351C04:
    // 0x84351C04: jal         0x84351ADC
    // 0x84351C08: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84351ADC(rdram, ctx);
        goto after_0;
    // 0x84351C08: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_0:
    // 0x84351C0C: b           L_84351CA8
    // 0x84351C10: nop

        goto L_84351CA8;
    // 0x84351C10: nop

L_84351C14:
    // 0x84351C14: jal         0x8140BDD0
    // 0x84351C18: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140BDD0(rdram, ctx);
        goto after_1;
    // 0x84351C18: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_1:
    // 0x84351C1C: beq         $v0, $zero, L_84351CA8
    if (ctx->r2 == 0) {
        // 0x84351C20: nop
    
            goto L_84351CA8;
    }
    // 0x84351C20: nop

    // 0x84351C24: jal         0x81408328
    // 0x84351C28: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408328(rdram, ctx);
        goto after_2;
    // 0x84351C28: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_2:
    // 0x84351C2C: b           L_84351CA8
    // 0x84351C30: nop

        goto L_84351CA8;
    // 0x84351C30: nop

L_84351C34:
    // 0x84351C34: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8D06C) << 16);
    // 0x84351C38: lwc1        $f0, -0x2F94($at)
    ctx->f0.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8D06C));
    // 0x84351C3C: lui         $a1, 0x3E99
    ctx->r5 = S32(0X3E99 << 16);
    // 0x84351C40: ori         $a1, $a1, 0x999A
    ctx->r5 = ctx->r5 | 0X999A;
    // 0x84351C44: mfc1        $a2, $f0
    ctx->r6 = (int32_t)ctx->f0.u32l;
    // 0x84351C48: jal         0x8140B9D0
    // 0x84351C4C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140B9D0(rdram, ctx);
        goto after_3;
    // 0x84351C4C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_3:
    // 0x84351C50: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84351C54: lui         $a1, 0x4040
    ctx->r5 = S32(0X4040 << 16);
    // 0x84351C58: jal         0x8140ADBC
    // 0x84351C5C: lui         $a2, 0x3F80
    ctx->r6 = S32(0X3F80 << 16);
    func_8140ADBC(rdram, ctx);
        goto after_4;
    // 0x84351C5C: lui         $a2, 0x3F80
    ctx->r6 = S32(0X3F80 << 16);
    after_4:
    // 0x84351C60: b           L_84351CA8
    // 0x84351C64: nop

        goto L_84351CA8;
    // 0x84351C64: nop

L_84351C68:
    // 0x84351C68: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84351C6C: jal         0x8140826C
    // 0x84351C70: addiu       $a1, $zero, 0x2
    ctx->r5 = ADD32(0, 0X2);
    func_8140826C(rdram, ctx);
        goto after_5;
    // 0x84351C70: addiu       $a1, $zero, 0x2
    ctx->r5 = ADD32(0, 0X2);
    after_5:
    // 0x84351C74: b           L_84351CA8
    // 0x84351C78: nop

        goto L_84351CA8;
    // 0x84351C78: nop

L_84351C7C:
    // 0x84351C7C: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8D070) << 16);
    // 0x84351C80: lwc1        $f0, -0x2F90($at)
    ctx->f0.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8D070));
    // 0x84351C84: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84351C88: mfc1        $a1, $f0
    ctx->r5 = (int32_t)ctx->f0.u32l;
    // 0x84351C8C: mfc1        $a2, $f0
    ctx->r6 = (int32_t)ctx->f0.u32l;
    // 0x84351C90: jal         0x8140B9D0
    // 0x84351C94: nop

    func_8140B9D0(rdram, ctx);
        goto after_6;
    // 0x84351C94: nop

    after_6:
    // 0x84351C98: b           L_84351CA8
    // 0x84351C9C: nop

        goto L_84351CA8;
    // 0x84351C9C: nop

L_84351CA0:
    // 0x84351CA0: jal         0x81408150
    // 0x84351CA4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408150(rdram, ctx);
        goto after_7;
    // 0x84351CA4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_7:
L_84351CA8:
    // 0x84351CA8: jal         0x81408368
    // 0x84351CAC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408368(rdram, ctx);
        goto after_8;
    // 0x84351CAC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_8:
    // 0x84351CB0: beql        $v0, $zero, L_84351CD4
    if (ctx->r2 == 0) {
        // 0x84351CB4: lw          $ra, 0x1C($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X1C);
            goto L_84351CD4;
    }
    goto skip_0;
    // 0x84351CB4: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    skip_0:
    // 0x84351CB8: jal         0x8140A4DC
    // 0x84351CBC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A4DC(rdram, ctx);
        goto after_9;
    // 0x84351CBC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_9:
    // 0x84351CC0: jal         0x8140B2B4
    // 0x84351CC4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140B2B4(rdram, ctx);
        goto after_10;
    // 0x84351CC4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_10:
    // 0x84351CC8: jal         0x81409BDC
    // 0x84351CCC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81409BDC(rdram, ctx);
        goto after_11;
    // 0x84351CCC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_11:
    // 0x84351CD0: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
L_84351CD4:
    // 0x84351CD4: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x84351CD8: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    // 0x84351CDC: jr          $ra
    // 0x84351CE0: nop

    return;
    // 0x84351CE0: nop

;}
RECOMP_FUNC void func_8432C1E0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8432C1E0: addiu       $sp, $sp, -0x30
    ctx->r29 = ADD32(ctx->r29, -0X30);
    // 0x8432C1E4: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X902E0) << 16);
    // 0x8432C1E8: sb          $a1, 0x2E0($at)
    MEM_B((int16_t)RELOC_LO16(259, 0X902E0), ctx->r1) = ctx->r5;
    // 0x8432C1EC: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8432C1F0: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x8432C1F4: sw          $s3, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r19;
    // 0x8432C1F8: sw          $s2, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r18;
    // 0x8432C1FC: sw          $s1, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r17;
    // 0x8432C200: bne         $a2, $at, L_8432C328
    if (ctx->r6 != ctx->r1) {
        // 0x8432C204: sw          $s0, 0x14($sp)
        MEM_W(0X14, ctx->r29) = ctx->r16;
            goto L_8432C328;
    }
    // 0x8432C204: sw          $s0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r16;
    // 0x8432C208: sltiu       $at, $a1, 0xA
    ctx->r1 = ctx->r5 < 0XA ? 1 : 0;
    // 0x8432C20C: beq         $at, $zero, L_8432C2AC
    if (ctx->r1 == 0) {
        // 0x8432C210: sll         $t6, $a1, 2
        ctx->r14 = S32(ctx->r5 << 2);
            goto L_8432C2AC;
    }
    // 0x8432C210: sll         $t6, $a1, 2
    ctx->r14 = S32(ctx->r5 << 2);
    // 0x8432C214: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8BE90) << 16);
    // 0x8432C218: addu        $at, $at, $t6
    gpr jr_addend_8432C220 = ctx->r14;
    ctx->r1 = ADD32(ctx->r1, ctx->r14);
    // 0x8432C21C: lw          $t6, -0x4170($at)
    ctx->r14 = ADD32(ctx->r1, (int16_t)RELOC_LO16(259, 0X8BE90));
    // 0x8432C220: jr          $t6
    // 0x8432C224: nop

    switch (jr_addend_8432C220 >> 2) {
        case 0: goto L_8432C228; break;
        case 1: goto L_8432C248; break;
        case 2: goto L_8432C2AC; break;
        case 3: goto L_8432C268; break;
        case 4: goto L_8432C280; break;
        case 5: goto L_8432C2AC; break;
        case 6: goto L_8432C2AC; break;
        case 7: goto L_8432C2AC; break;
        case 8: goto L_8432C2AC; break;
        case 9: goto L_8432C298; break;
        default: switch_error(__func__, 0x8432C220, 0x8438BE90);
    }
    // 0x8432C224: nop

L_8432C228:
    // 0x8432C228: sll         $t7, $a0, 2
    ctx->r15 = S32(ctx->r4 << 2);
    // 0x8432C22C: addu        $t7, $t7, $a0
    ctx->r15 = ADD32(ctx->r15, ctx->r4);
    // 0x8432C230: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x8432C234: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86E08) << 16);
    // 0x8432C238: addu        $s0, $s0, $t7
    ctx->r16 = ADD32(ctx->r16, ctx->r15);
    // 0x8432C23C: lw          $s0, 0x6E08($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86E08));
    // 0x8432C240: b           L_8432C2AC
    // 0x8432C244: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
        goto L_8432C2AC;
    // 0x8432C244: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
L_8432C248:
    // 0x8432C248: sll         $t8, $a0, 2
    ctx->r24 = S32(ctx->r4 << 2);
    // 0x8432C24C: addu        $t8, $t8, $a0
    ctx->r24 = ADD32(ctx->r24, ctx->r4);
    // 0x8432C250: sll         $t8, $t8, 2
    ctx->r24 = S32(ctx->r24 << 2);
    // 0x8432C254: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86E0C) << 16);
    // 0x8432C258: addu        $s0, $s0, $t8
    ctx->r16 = ADD32(ctx->r16, ctx->r24);
    // 0x8432C25C: lw          $s0, 0x6E0C($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86E0C));
    // 0x8432C260: b           L_8432C2AC
    // 0x8432C264: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
        goto L_8432C2AC;
    // 0x8432C264: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
L_8432C268:
    // 0x8432C268: sll         $t9, $a0, 3
    ctx->r25 = S32(ctx->r4 << 3);
    // 0x8432C26C: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86D44) << 16);
    // 0x8432C270: addu        $s0, $s0, $t9
    ctx->r16 = ADD32(ctx->r16, ctx->r25);
    // 0x8432C274: lw          $s0, 0x6D44($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86D44));
    // 0x8432C278: b           L_8432C2AC
    // 0x8432C27C: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
        goto L_8432C2AC;
    // 0x8432C27C: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
L_8432C280:
    // 0x8432C280: sll         $t0, $a0, 2
    ctx->r8 = S32(ctx->r4 << 2);
    // 0x8432C284: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86DBC) << 16);
    // 0x8432C288: addu        $s0, $s0, $t0
    ctx->r16 = ADD32(ctx->r16, ctx->r8);
    // 0x8432C28C: lw          $s0, 0x6DBC($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86DBC));
    // 0x8432C290: b           L_8432C2AC
    // 0x8432C294: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
        goto L_8432C2AC;
    // 0x8432C294: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
L_8432C298:
    // 0x8432C298: sll         $t1, $a0, 2
    ctx->r9 = S32(ctx->r4 << 2);
    // 0x8432C29C: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86E00) << 16);
    // 0x8432C2A0: addu        $s0, $s0, $t1
    ctx->r16 = ADD32(ctx->r16, ctx->r9);
    // 0x8432C2A4: lw          $s0, 0x6E00($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86E00));
    // 0x8432C2A8: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
L_8432C2AC:
    // 0x8432C2AC: lw          $s0, 0x2C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X2C);
    // 0x8432C2B0: lui         $s3, 0x8439
    ctx->r19 = S32(RELOC_HI16(259, 0X88A50) << 16);
    // 0x8432C2B4: lui         $s2, 0x8439
    ctx->r18 = S32(RELOC_HI16(259, 0X88668) << 16);
    // 0x8432C2B8: lbu         $v0, 0x0($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C2BC: addiu       $s2, $s2, -0x7998
    ctx->r18 = ADD32(ctx->r18, (int16_t)RELOC_LO16(259, 0X88668));
    // 0x8432C2C0: addiu       $s3, $s3, -0x75B0
    ctx->r19 = ADD32(ctx->r19, (int16_t)RELOC_LO16(259, 0X88A50));
    // 0x8432C2C4: beq         $v0, $zero, L_8432C3DC
    if (ctx->r2 == 0) {
        // 0x8432C2C8: lui         $s1, 0x8439
        ctx->r17 = S32(RELOC_HI16(259, 0X88280) << 16);
            goto L_8432C3DC;
    }
    // 0x8432C2C8: lui         $s1, 0x8439
    ctx->r17 = S32(RELOC_HI16(259, 0X88280) << 16);
    // 0x8432C2CC: addiu       $s1, $s1, -0x7D80
    ctx->r17 = ADD32(ctx->r17, (int16_t)RELOC_LO16(259, 0X88280));
    // 0x8432C2D0: sll         $a0, $v0, 16
    ctx->r4 = S32(ctx->r2 << 16);
L_8432C2D4:
    // 0x8432C2D4: jal         0x8432C0D0
    // 0x8432C2D8: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    func_8432C0D0(rdram, ctx);
        goto after_0;
    // 0x8432C2D8: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    after_0:
    // 0x8432C2DC: lbu         $t2, 0x0($s0)
    ctx->r10 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C2E0: sll         $t3, $t2, 2
    ctx->r11 = S32(ctx->r10 << 2);
    // 0x8432C2E4: addu        $t4, $s1, $t3
    ctx->r12 = ADD32(ctx->r17, ctx->r11);
    // 0x8432C2E8: lw          $t9, 0x0($t4)
    ctx->r25 = MEM_W(ctx->r12, 0X0);
    // 0x8432C2EC: jalr        $t9
    // 0x8432C2F0: nop

    LOOKUP_FUNC(ctx->r25)(rdram, ctx);
        goto after_1;
    // 0x8432C2F0: nop

    after_1:
    // 0x8432C2F4: lbu         $v0, 0x0($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C2F8: sll         $v0, $v0, 2
    ctx->r2 = S32(ctx->r2 << 2);
    // 0x8432C2FC: addu        $t5, $s2, $v0
    ctx->r13 = ADD32(ctx->r18, ctx->r2);
    // 0x8432C300: addu        $t6, $s3, $v0
    ctx->r14 = ADD32(ctx->r19, ctx->r2);
    // 0x8432C304: lw          $a1, 0x0($t6)
    ctx->r5 = MEM_W(ctx->r14, 0X0);
    // 0x8432C308: jal         0x8432C194
    // 0x8432C30C: lw          $a0, 0x0($t5)
    ctx->r4 = MEM_W(ctx->r13, 0X0);
    func_8432C194(rdram, ctx);
        goto after_2;
    // 0x8432C30C: lw          $a0, 0x0($t5)
    ctx->r4 = MEM_W(ctx->r13, 0X0);
    after_2:
    // 0x8432C310: lbu         $v0, 0x1($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X1);
    // 0x8432C314: addiu       $s0, $s0, 0x1
    ctx->r16 = ADD32(ctx->r16, 0X1);
    // 0x8432C318: bnel        $v0, $zero, L_8432C2D4
    if (ctx->r2 != 0) {
        // 0x8432C31C: sll         $a0, $v0, 16
        ctx->r4 = S32(ctx->r2 << 16);
            goto L_8432C2D4;
    }
    goto skip_0;
    // 0x8432C31C: sll         $a0, $v0, 16
    ctx->r4 = S32(ctx->r2 << 16);
    skip_0:
    // 0x8432C320: b           L_8432C3E0
    // 0x8432C324: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
        goto L_8432C3E0;
    // 0x8432C324: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_8432C328:
    // 0x8432C328: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x8432C32C: beq         $a1, $at, L_8432C348
    if (ctx->r5 == ctx->r1) {
        // 0x8432C330: sll         $t7, $a0, 2
        ctx->r15 = S32(ctx->r4 << 2);
            goto L_8432C348;
    }
    // 0x8432C330: sll         $t7, $a0, 2
    ctx->r15 = S32(ctx->r4 << 2);
    // 0x8432C334: addiu       $at, $zero, 0x6
    ctx->r1 = ADD32(0, 0X6);
    // 0x8432C338: beq         $a1, $at, L_8432C360
    if (ctx->r5 == ctx->r1) {
        // 0x8432C33C: sll         $t8, $a0, 2
        ctx->r24 = S32(ctx->r4 << 2);
            goto L_8432C360;
    }
    // 0x8432C33C: sll         $t8, $a0, 2
    ctx->r24 = S32(ctx->r4 << 2);
    // 0x8432C340: b           L_8432C36C
    // 0x8432C344: lw          $s0, 0x2C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X2C);
        goto L_8432C36C;
    // 0x8432C344: lw          $s0, 0x2C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X2C);
L_8432C348:
    // 0x8432C348: addu        $t7, $t7, $a0
    ctx->r15 = ADD32(ctx->r15, ctx->r4);
    // 0x8432C34C: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x8432C350: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86E10) << 16);
    // 0x8432C354: addu        $s0, $s0, $t7
    ctx->r16 = ADD32(ctx->r16, ctx->r15);
    // 0x8432C358: b           L_8432C36C
    // 0x8432C35C: lw          $s0, 0x6E10($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86E10));
        goto L_8432C36C;
    // 0x8432C35C: lw          $s0, 0x6E10($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86E10));
L_8432C360:
    // 0x8432C360: lui         $s0, 0x8438
    ctx->r16 = S32(RELOC_HI16(259, 0X86DEC) << 16);
    // 0x8432C364: addu        $s0, $s0, $t8
    ctx->r16 = ADD32(ctx->r16, ctx->r24);
    // 0x8432C368: lw          $s0, 0x6DEC($s0)
    ctx->r16 = MEM_W(ctx->r16, (int16_t)RELOC_LO16(259, 0X86DEC));
L_8432C36C:
    // 0x8432C36C: lbu         $v0, 0x0($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C370: lui         $s3, 0x8439
    ctx->r19 = S32(RELOC_HI16(259, 0X88CA8) << 16);
    // 0x8432C374: addiu       $s3, $s3, -0x7358
    ctx->r19 = ADD32(ctx->r19, (int16_t)RELOC_LO16(259, 0X88CA8));
    // 0x8432C378: beq         $v0, $zero, L_8432C3DC
    if (ctx->r2 == 0) {
        // 0x8432C37C: lui         $s2, 0x8439
        ctx->r18 = S32(RELOC_HI16(259, 0X888C0) << 16);
            goto L_8432C3DC;
    }
    // 0x8432C37C: lui         $s2, 0x8439
    ctx->r18 = S32(RELOC_HI16(259, 0X888C0) << 16);
    // 0x8432C380: lui         $s1, 0x8439
    ctx->r17 = S32(RELOC_HI16(259, 0X884D8) << 16);
    // 0x8432C384: addiu       $s1, $s1, -0x7B28
    ctx->r17 = ADD32(ctx->r17, (int16_t)RELOC_LO16(259, 0X884D8));
    // 0x8432C388: addiu       $s2, $s2, -0x7740
    ctx->r18 = ADD32(ctx->r18, (int16_t)RELOC_LO16(259, 0X888C0));
    // 0x8432C38C: sll         $a0, $v0, 16
    ctx->r4 = S32(ctx->r2 << 16);
L_8432C390:
    // 0x8432C390: jal         0x8432C14C
    // 0x8432C394: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    func_8432C14C(rdram, ctx);
        goto after_3;
    // 0x8432C394: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    after_3:
    // 0x8432C398: lbu         $t0, 0x0($s0)
    ctx->r8 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C39C: sll         $t1, $t0, 2
    ctx->r9 = S32(ctx->r8 << 2);
    // 0x8432C3A0: addu        $t2, $s1, $t1
    ctx->r10 = ADD32(ctx->r17, ctx->r9);
    // 0x8432C3A4: lw          $t9, 0x0($t2)
    ctx->r25 = MEM_W(ctx->r10, 0X0);
    // 0x8432C3A8: jalr        $t9
    // 0x8432C3AC: nop

    LOOKUP_FUNC(ctx->r25)(rdram, ctx);
        goto after_4;
    // 0x8432C3AC: nop

    after_4:
    // 0x8432C3B0: lbu         $v0, 0x0($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X0);
    // 0x8432C3B4: sll         $v0, $v0, 2
    ctx->r2 = S32(ctx->r2 << 2);
    // 0x8432C3B8: addu        $t3, $s2, $v0
    ctx->r11 = ADD32(ctx->r18, ctx->r2);
    // 0x8432C3BC: addu        $t4, $s3, $v0
    ctx->r12 = ADD32(ctx->r19, ctx->r2);
    // 0x8432C3C0: lw          $a1, 0x0($t4)
    ctx->r5 = MEM_W(ctx->r12, 0X0);
    // 0x8432C3C4: jal         0x8432C194
    // 0x8432C3C8: lw          $a0, 0x0($t3)
    ctx->r4 = MEM_W(ctx->r11, 0X0);
    func_8432C194(rdram, ctx);
        goto after_5;
    // 0x8432C3C8: lw          $a0, 0x0($t3)
    ctx->r4 = MEM_W(ctx->r11, 0X0);
    after_5:
    // 0x8432C3CC: lbu         $v0, 0x1($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X1);
    // 0x8432C3D0: addiu       $s0, $s0, 0x1
    ctx->r16 = ADD32(ctx->r16, 0X1);
    // 0x8432C3D4: bnel        $v0, $zero, L_8432C390
    if (ctx->r2 != 0) {
        // 0x8432C3D8: sll         $a0, $v0, 16
        ctx->r4 = S32(ctx->r2 << 16);
            goto L_8432C390;
    }
    goto skip_1;
    // 0x8432C3D8: sll         $a0, $v0, 16
    ctx->r4 = S32(ctx->r2 << 16);
    skip_1:
L_8432C3DC:
    // 0x8432C3DC: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
L_8432C3E0:
    // 0x8432C3E0: lw          $s0, 0x14($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X14);
    // 0x8432C3E4: lw          $s1, 0x18($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X18);
    // 0x8432C3E8: lw          $s2, 0x1C($sp)
    ctx->r18 = MEM_W(ctx->r29, 0X1C);
    // 0x8432C3EC: lw          $s3, 0x20($sp)
    ctx->r19 = MEM_W(ctx->r29, 0X20);
    // 0x8432C3F0: jr          $ra
    // 0x8432C3F4: addiu       $sp, $sp, 0x30
    ctx->r29 = ADD32(ctx->r29, 0X30);
    return;
    // 0x8432C3F4: addiu       $sp, $sp, 0x30
    ctx->r29 = ADD32(ctx->r29, 0X30);
;}
RECOMP_FUNC void func_8436C3CC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8436C3CC: addiu       $sp, $sp, -0x70
    ctx->r29 = ADD32(ctx->r29, -0X70);
    // 0x8436C3D0: sw          $ra, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r31;
    // 0x8436C3D4: or          $a1, $a0, $zero
    ctx->r5 = ctx->r4 | 0;
    // 0x8436C3D8: sdc1        $f24, 0x20($sp)
    CHECK_FR(ctx, 24);
    SD(ctx->f24.u64, 0X20, ctx->r29);
    // 0x8436C3DC: sdc1        $f22, 0x18($sp)
    CHECK_FR(ctx, 22);
    SD(ctx->f22.u64, 0X18, ctx->r29);
    // 0x8436C3E0: sdc1        $f20, 0x10($sp)
    CHECK_FR(ctx, 20);
    SD(ctx->f20.u64, 0X10, ctx->r29);
    // 0x8436C3E4: sw          $a1, 0x70($sp)
    MEM_W(0X70, ctx->r29) = ctx->r5;
    // 0x8436C3E8: jal         0x8432FBBC
    // 0x8436C3EC: addiu       $a0, $sp, 0x58
    ctx->r4 = ADD32(ctx->r29, 0X58);
    func_8432FBBC(rdram, ctx);
        goto after_0;
    // 0x8436C3EC: addiu       $a0, $sp, 0x58
    ctx->r4 = ADD32(ctx->r29, 0X58);
    after_0:
    // 0x8436C3F0: jal         0x8432FC14
    // 0x8436C3F4: addiu       $a0, $sp, 0x4C
    ctx->r4 = ADD32(ctx->r29, 0X4C);
    func_8432FC14(rdram, ctx);
        goto after_1;
    // 0x8436C3F4: addiu       $a0, $sp, 0x4C
    ctx->r4 = ADD32(ctx->r29, 0X4C);
    after_1:
    // 0x8436C3F8: lui         $at, 0x4348
    ctx->r1 = S32(0X4348 << 16);
    // 0x8436C3FC: mtc1        $at, $f0
    ctx->f0.u32l = ctx->r1;
    // 0x8436C400: lwc1        $f4, 0x50($sp)
    ctx->f4.u32l = MEM_W(ctx->r29, 0X50);
    // 0x8436C404: lw          $a1, 0x70($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X70);
    // 0x8436C408: lui         $at, 0x3F40
    ctx->r1 = S32(0X3F40 << 16);
    // 0x8436C40C: c.lt.s      $f0, $f4
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 4);
    c1cs = ctx->f0.fl < ctx->f4.fl;
    // 0x8436C410: mtc1        $at, $f24
    ctx->f24.u32l = ctx->r1;
    // 0x8436C414: lui         $at, 0x3F00
    ctx->r1 = S32(0X3F00 << 16);
    // 0x8436C418: or          $a2, $zero, $zero
    ctx->r6 = 0 | 0;
    // 0x8436C41C: bc1f        L_8436C428
    if (!c1cs) {
        // 0x8436C420: addiu       $v0, $a1, 0xB0
        ctx->r2 = ADD32(ctx->r5, 0XB0);
            goto L_8436C428;
    }
    // 0x8436C420: addiu       $v0, $a1, 0xB0
    ctx->r2 = ADD32(ctx->r5, 0XB0);
    // 0x8436C424: swc1        $f0, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->f0.u32l;
L_8436C428:
    // 0x8436C428: mtc1        $at, $f22
    ctx->f22.u32l = ctx->r1;
    // 0x8436C42C: lui         $at, 0x4110
    ctx->r1 = S32(0X4110 << 16);
    // 0x8436C430: mtc1        $at, $f20
    ctx->f20.u32l = ctx->r1;
    // 0x8436C434: lui         $at, 0x3F80
    ctx->r1 = S32(0X3F80 << 16);
    // 0x8436C438: mtc1        $at, $f18
    ctx->f18.u32l = ctx->r1;
    // 0x8436C43C: addiu       $t2, $zero, 0x2
    ctx->r10 = ADD32(0, 0X2);
    // 0x8436C440: addiu       $t1, $zero, 0x1
    ctx->r9 = ADD32(0, 0X1);
    // 0x8436C444: addiu       $t0, $zero, 0x9
    ctx->r8 = ADD32(0, 0X9);
    // 0x8436C448: addiu       $a3, $zero, 0xA
    ctx->r7 = ADD32(0, 0XA);
L_8436C44C:
    // 0x8436C44C: lh          $v1, 0x2($a1)
    ctx->r3 = MEM_H(ctx->r5, 0X2);
    // 0x8436C450: lh          $a0, 0x4($a1)
    ctx->r4 = MEM_H(ctx->r5, 0X4);
    // 0x8436C454: slt         $at, $v1, $a0
    ctx->r1 = SIGNED(ctx->r3) < SIGNED(ctx->r4) ? 1 : 0;
    // 0x8436C458: beql        $at, $zero, L_8436C498
    if (ctx->r1 == 0) {
        // 0x8436C45C: mtc1        $a2, $f8
        ctx->f8.u32l = ctx->r6;
            goto L_8436C498;
    }
    goto skip_0;
    // 0x8436C45C: mtc1        $a2, $f8
    ctx->f8.u32l = ctx->r6;
    skip_0:
    // 0x8436C460: mtc1        $v1, $f6
    ctx->f6.u32l = ctx->r3;
    // 0x8436C464: mtc1        $a2, $f10
    ctx->f10.u32l = ctx->r6;
    // 0x8436C468: addiu       $t6, $a0, -0x1
    ctx->r14 = ADD32(ctx->r4, -0X1);
    // 0x8436C46C: cvt.s.w     $f8, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.fl = CVT_S_W(ctx->f6.u32l);
    // 0x8436C470: cvt.s.w     $f4, $f10
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    ctx->f4.fl = CVT_S_W(ctx->f10.u32l);
    // 0x8436C474: mtc1        $t6, $f10
    ctx->f10.u32l = ctx->r14;
    // 0x8436C478: nop

    // 0x8436C47C: cvt.s.w     $f16, $f10
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 10);
    ctx->f16.fl = CVT_S_W(ctx->f10.u32l);
    // 0x8436C480: mul.s       $f6, $f8, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f6.fl = MUL_S(ctx->f8.fl, ctx->f4.fl);
    // 0x8436C484: div.s       $f14, $f6, $f20
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 20);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f20.fl); 
    ctx->f14.fl = DIV_S(ctx->f6.fl, ctx->f20.fl);
    // 0x8436C488: div.s       $f2, $f14, $f16
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f14.fl); NAN_CHECK(ctx->f16.fl); 
    ctx->f2.fl = DIV_S(ctx->f14.fl, ctx->f16.fl);
    // 0x8436C48C: b           L_8436C4A8
    // 0x8436C490: sub.s       $f12, $f18, $f2
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f18.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f12.fl = ctx->f18.fl - ctx->f2.fl;
        goto L_8436C4A8;
    // 0x8436C490: sub.s       $f12, $f18, $f2
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f18.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f12.fl = ctx->f18.fl - ctx->f2.fl;
    // 0x8436C494: mtc1        $a2, $f8
    ctx->f8.u32l = ctx->r6;
L_8436C498:
    // 0x8436C498: nop

    // 0x8436C49C: cvt.s.w     $f4, $f8
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 8);
    ctx->f4.fl = CVT_S_W(ctx->f8.u32l);
    // 0x8436C4A0: div.s       $f2, $f4, $f20
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 20);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f20.fl); 
    ctx->f2.fl = DIV_S(ctx->f4.fl, ctx->f20.fl);
    // 0x8436C4A4: sub.s       $f12, $f18, $f2
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f18.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f12.fl = ctx->f18.fl - ctx->f2.fl;
L_8436C4A8:
    // 0x8436C4A8: lwc1        $f6, 0x58($sp)
    ctx->f6.u32l = MEM_W(ctx->r29, 0X58);
    // 0x8436C4AC: lwc1        $f8, 0x4C($sp)
    ctx->f8.u32l = MEM_W(ctx->r29, 0X4C);
    // 0x8436C4B0: mul.s       $f10, $f6, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f12.fl); 
    ctx->f10.fl = MUL_S(ctx->f6.fl, ctx->f12.fl);
    // 0x8436C4B4: nop

    // 0x8436C4B8: mul.s       $f4, $f8, $f2
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f4.fl = MUL_S(ctx->f8.fl, ctx->f2.fl);
    // 0x8436C4BC: add.s       $f6, $f10, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f6.fl = ctx->f10.fl + ctx->f4.fl;
    // 0x8436C4C0: swc1        $f6, 0x10($v0)
    MEM_W(0X10, ctx->r2) = ctx->f6.u32l;
    // 0x8436C4C4: lwc1        $f8, 0x5C($sp)
    ctx->f8.u32l = MEM_W(ctx->r29, 0X5C);
    // 0x8436C4C8: lwc1        $f4, 0x50($sp)
    ctx->f4.u32l = MEM_W(ctx->r29, 0X50);
    // 0x8436C4CC: mul.s       $f10, $f8, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f12.fl); 
    ctx->f10.fl = MUL_S(ctx->f8.fl, ctx->f12.fl);
    // 0x8436C4D0: nop

    // 0x8436C4D4: mul.s       $f6, $f4, $f2
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f6.fl = MUL_S(ctx->f4.fl, ctx->f2.fl);
    // 0x8436C4D8: add.s       $f8, $f10, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f6.fl); 
    ctx->f8.fl = ctx->f10.fl + ctx->f6.fl;
    // 0x8436C4DC: swc1        $f8, 0x14($v0)
    MEM_W(0X14, ctx->r2) = ctx->f8.u32l;
    // 0x8436C4E0: lwc1        $f4, 0x60($sp)
    ctx->f4.u32l = MEM_W(ctx->r29, 0X60);
    // 0x8436C4E4: lwc1        $f6, 0x54($sp)
    ctx->f6.u32l = MEM_W(ctx->r29, 0X54);
    // 0x8436C4E8: mul.s       $f10, $f4, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f12.fl); 
    ctx->f10.fl = MUL_S(ctx->f4.fl, ctx->f12.fl);
    // 0x8436C4EC: nop

    // 0x8436C4F0: mul.s       $f8, $f6, $f2
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f8.fl = MUL_S(ctx->f6.fl, ctx->f2.fl);
    // 0x8436C4F4: lwc1        $f6, 0xC($v0)
    ctx->f6.u32l = MEM_W(ctx->r2, 0XC);
    // 0x8436C4F8: add.s       $f4, $f10, $f8
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f8.fl); 
    ctx->f4.fl = ctx->f10.fl + ctx->f8.fl;
    // 0x8436C4FC: swc1        $f4, 0x18($v0)
    MEM_W(0X18, ctx->r2) = ctx->f4.u32l;
    // 0x8436C500: lwc1        $f10, 0xC($a1)
    ctx->f10.u32l = MEM_W(ctx->r5, 0XC);
    // 0x8436C504: add.s       $f8, $f6, $f10
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f8.fl = ctx->f6.fl + ctx->f10.fl;
    // 0x8436C508: bne         $a2, $zero, L_8436C518
    if (ctx->r6 != 0) {
        // 0x8436C50C: swc1        $f8, 0xC($v0)
        MEM_W(0XC, ctx->r2) = ctx->f8.u32l;
            goto L_8436C518;
    }
    // 0x8436C50C: swc1        $f8, 0xC($v0)
    MEM_W(0XC, ctx->r2) = ctx->f8.u32l;
    // 0x8436C510: b           L_8436C608
    // 0x8436C514: swc1        $f18, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f18.u32l;
        goto L_8436C608;
    // 0x8436C514: swc1        $f18, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f18.u32l;
L_8436C518:
    // 0x8436C518: bne         $a2, $t0, L_8436C564
    if (ctx->r6 != ctx->r8) {
        // 0x8436C51C: nop
    
            goto L_8436C564;
    }
    // 0x8436C51C: nop

    // 0x8436C520: lh          $t7, 0x2($a1)
    ctx->r15 = MEM_H(ctx->r5, 0X2);
    // 0x8436C524: slti        $at, $t7, 0x5
    ctx->r1 = SIGNED(ctx->r15) < 0X5 ? 1 : 0;
    // 0x8436C528: beql        $at, $zero, L_8436C53C
    if (ctx->r1 == 0) {
        // 0x8436C52C: lwc1        $f4, 0x8($v0)
        ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
            goto L_8436C53C;
    }
    goto skip_1;
    // 0x8436C52C: lwc1        $f4, 0x8($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
    skip_1:
    // 0x8436C530: b           L_8436C608
    // 0x8436C534: swc1        $f18, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f18.u32l;
        goto L_8436C608;
    // 0x8436C534: swc1        $f18, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f18.u32l;
    // 0x8436C538: lwc1        $f4, 0x8($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
L_8436C53C:
    // 0x8436C53C: add.s       $f6, $f4, $f22
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 22);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f22.fl); 
    ctx->f6.fl = ctx->f4.fl + ctx->f22.fl;
    // 0x8436C540: swc1        $f6, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f6.u32l;
    // 0x8436C544: lwc1        $f10, 0x8($v0)
    ctx->f10.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C548: lwc1        $f0, 0x8($a1)
    ctx->f0.u32l = MEM_W(ctx->r5, 0X8);
    // 0x8436C54C: c.lt.s      $f0, $f10
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    c1cs = ctx->f0.fl < ctx->f10.fl;
    // 0x8436C550: nop

    // 0x8436C554: bc1fl       L_8436C60C
    if (!c1cs) {
        // 0x8436C558: addiu       $a2, $a2, 0x1
        ctx->r6 = ADD32(ctx->r6, 0X1);
            goto L_8436C60C;
    }
    goto skip_2;
    // 0x8436C558: addiu       $a2, $a2, 0x1
    ctx->r6 = ADD32(ctx->r6, 0X1);
    skip_2:
    // 0x8436C55C: b           L_8436C608
    // 0x8436C560: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
        goto L_8436C608;
    // 0x8436C560: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
L_8436C564:
    // 0x8436C564: bne         $a2, $t1, L_8436C5A0
    if (ctx->r6 != ctx->r9) {
        // 0x8436C568: nop
    
            goto L_8436C5A0;
    }
    // 0x8436C568: nop

    // 0x8436C56C: lwc1        $f8, 0x8($v0)
    ctx->f8.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C570: lwc1        $f4, 0x10($a1)
    ctx->f4.u32l = MEM_W(ctx->r5, 0X10);
    // 0x8436C574: add.s       $f6, $f8, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f6.fl = ctx->f8.fl + ctx->f4.fl;
    // 0x8436C578: swc1        $f6, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f6.u32l;
    // 0x8436C57C: lwc1        $f10, 0x8($a1)
    ctx->f10.u32l = MEM_W(ctx->r5, 0X8);
    // 0x8436C580: lwc1        $f8, 0x8($v0)
    ctx->f8.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C584: mul.s       $f0, $f10, $f22
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 22);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f22.fl); 
    ctx->f0.fl = MUL_S(ctx->f10.fl, ctx->f22.fl);
    // 0x8436C588: c.lt.s      $f0, $f8
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 8);
    c1cs = ctx->f0.fl < ctx->f8.fl;
    // 0x8436C58C: nop

    // 0x8436C590: bc1fl       L_8436C60C
    if (!c1cs) {
        // 0x8436C594: addiu       $a2, $a2, 0x1
        ctx->r6 = ADD32(ctx->r6, 0X1);
            goto L_8436C60C;
    }
    goto skip_3;
    // 0x8436C594: addiu       $a2, $a2, 0x1
    ctx->r6 = ADD32(ctx->r6, 0X1);
    skip_3:
    // 0x8436C598: b           L_8436C608
    // 0x8436C59C: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
        goto L_8436C608;
    // 0x8436C59C: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
L_8436C5A0:
    // 0x8436C5A0: bnel        $a2, $t2, L_8436C5E0
    if (ctx->r6 != ctx->r10) {
        // 0x8436C5A4: lwc1        $f6, 0x8($v0)
        ctx->f6.u32l = MEM_W(ctx->r2, 0X8);
            goto L_8436C5E0;
    }
    goto skip_4;
    // 0x8436C5A4: lwc1        $f6, 0x8($v0)
    ctx->f6.u32l = MEM_W(ctx->r2, 0X8);
    skip_4:
    // 0x8436C5A8: lwc1        $f4, 0x8($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C5AC: lwc1        $f6, 0x10($a1)
    ctx->f6.u32l = MEM_W(ctx->r5, 0X10);
    // 0x8436C5B0: add.s       $f10, $f4, $f6
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f6.fl); 
    ctx->f10.fl = ctx->f4.fl + ctx->f6.fl;
    // 0x8436C5B4: swc1        $f10, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f10.u32l;
    // 0x8436C5B8: lwc1        $f8, 0x8($a1)
    ctx->f8.u32l = MEM_W(ctx->r5, 0X8);
    // 0x8436C5BC: lwc1        $f4, 0x8($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C5C0: mul.s       $f0, $f8, $f24
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 24);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f24.fl); 
    ctx->f0.fl = MUL_S(ctx->f8.fl, ctx->f24.fl);
    // 0x8436C5C4: c.lt.s      $f0, $f4
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 4);
    c1cs = ctx->f0.fl < ctx->f4.fl;
    // 0x8436C5C8: nop

    // 0x8436C5CC: bc1fl       L_8436C60C
    if (!c1cs) {
        // 0x8436C5D0: addiu       $a2, $a2, 0x1
        ctx->r6 = ADD32(ctx->r6, 0X1);
            goto L_8436C60C;
    }
    goto skip_5;
    // 0x8436C5D0: addiu       $a2, $a2, 0x1
    ctx->r6 = ADD32(ctx->r6, 0X1);
    skip_5:
    // 0x8436C5D4: b           L_8436C608
    // 0x8436C5D8: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
        goto L_8436C608;
    // 0x8436C5D8: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
    // 0x8436C5DC: lwc1        $f6, 0x8($v0)
    ctx->f6.u32l = MEM_W(ctx->r2, 0X8);
L_8436C5E0:
    // 0x8436C5E0: lwc1        $f10, 0x10($a1)
    ctx->f10.u32l = MEM_W(ctx->r5, 0X10);
    // 0x8436C5E4: add.s       $f8, $f6, $f10
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f8.fl = ctx->f6.fl + ctx->f10.fl;
    // 0x8436C5E8: swc1        $f8, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f8.u32l;
    // 0x8436C5EC: lwc1        $f4, 0x8($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X8);
    // 0x8436C5F0: lwc1        $f0, 0x8($a1)
    ctx->f0.u32l = MEM_W(ctx->r5, 0X8);
    // 0x8436C5F4: c.lt.s      $f0, $f4
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 4);
    c1cs = ctx->f0.fl < ctx->f4.fl;
    // 0x8436C5F8: nop

    // 0x8436C5FC: bc1fl       L_8436C60C
    if (!c1cs) {
        // 0x8436C600: addiu       $a2, $a2, 0x1
        ctx->r6 = ADD32(ctx->r6, 0X1);
            goto L_8436C60C;
    }
    goto skip_6;
    // 0x8436C600: addiu       $a2, $a2, 0x1
    ctx->r6 = ADD32(ctx->r6, 0X1);
    skip_6:
    // 0x8436C604: swc1        $f0, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->f0.u32l;
L_8436C608:
    // 0x8436C608: addiu       $a2, $a2, 0x1
    ctx->r6 = ADD32(ctx->r6, 0X1);
L_8436C60C:
    // 0x8436C60C: bne         $a2, $a3, L_8436C44C
    if (ctx->r6 != ctx->r7) {
        // 0x8436C610: addiu       $v0, $v0, 0x28
        ctx->r2 = ADD32(ctx->r2, 0X28);
            goto L_8436C44C;
    }
    // 0x8436C610: addiu       $v0, $v0, 0x28
    ctx->r2 = ADD32(ctx->r2, 0X28);
    // 0x8436C614: lw          $ra, 0x2C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X2C);
    // 0x8436C618: ldc1        $f20, 0x10($sp)
    CHECK_FR(ctx, 20);
    ctx->f20.u64 = LD(ctx->r29, 0X10);
    // 0x8436C61C: ldc1        $f22, 0x18($sp)
    CHECK_FR(ctx, 22);
    ctx->f22.u64 = LD(ctx->r29, 0X18);
    // 0x8436C620: ldc1        $f24, 0x20($sp)
    CHECK_FR(ctx, 24);
    ctx->f24.u64 = LD(ctx->r29, 0X20);
    // 0x8436C624: jr          $ra
    // 0x8436C628: addiu       $sp, $sp, 0x70
    ctx->r29 = ADD32(ctx->r29, 0X70);
    return;
    // 0x8436C628: addiu       $sp, $sp, 0x70
    ctx->r29 = ADD32(ctx->r29, 0X70);
;}
RECOMP_FUNC void func_8002DD98(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8002DD98: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x8002DD9C: addiu       $at, $zero, 0x100
    ctx->r1 = ADD32(0, 0X100);
    // 0x8002DDA0: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x8002DDA4: or          $a2, $a0, $zero
    ctx->r6 = ctx->r4 | 0;
    // 0x8002DDA8: beq         $a1, $at, L_8002DDF4
    if (ctx->r5 == ctx->r1) {
        // 0x8002DDAC: or          $v1, $zero, $zero
        ctx->r3 = 0 | 0;
            goto L_8002DDF4;
    }
    // 0x8002DDAC: or          $v1, $zero, $zero
    ctx->r3 = 0 | 0;
    // 0x8002DDB0: addiu       $at, $zero, 0x200
    ctx->r1 = ADD32(0, 0X200);
    // 0x8002DDB4: bne         $a1, $at, L_8002DE30
    if (ctx->r5 != ctx->r1) {
        // 0x8002DDB8: addiu       $a0, $zero, 0x1
        ctx->r4 = ADD32(0, 0X1);
            goto L_8002DE30;
    }
    // 0x8002DDB8: addiu       $a0, $zero, 0x1
    ctx->r4 = ADD32(0, 0X1);
    // 0x8002DDBC: jal         0x80048B90
    // 0x8002DDC0: sw          $a2, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r6;
    func_80048B90(rdram, ctx);
        goto after_0;
    // 0x8002DDC0: sw          $a2, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r6;
    after_0:
    // 0x8002DDC4: lw          $a2, 0x18($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X18);
    // 0x8002DDC8: addiu       $v1, $zero, 0x1
    ctx->r3 = ADD32(0, 0X1);
    // 0x8002DDCC: lw          $v0, 0x4($a2)
    ctx->r2 = MEM_W(ctx->r6, 0X4);
    // 0x8002DDD0: bnel        $v0, $zero, L_8002DDEC
    if (ctx->r2 != 0) {
        // 0x8002DDD4: addiu       $t8, $v0, -0x1
        ctx->r24 = ADD32(ctx->r2, -0X1);
            goto L_8002DDEC;
    }
    goto skip_0;
    // 0x8002DDD4: addiu       $t8, $v0, -0x1
    ctx->r24 = ADD32(ctx->r2, -0X1);
    skip_0:
    // 0x8002DDD8: lw          $t6, 0x8($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X8);
    // 0x8002DDDC: addu        $t7, $v0, $t6
    ctx->r15 = ADD32(ctx->r2, ctx->r14);
    // 0x8002DDE0: sw          $t7, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r15;
    // 0x8002DDE4: or          $v0, $t7, $zero
    ctx->r2 = ctx->r15 | 0;
    // 0x8002DDE8: addiu       $t8, $v0, -0x1
    ctx->r24 = ADD32(ctx->r2, -0X1);
L_8002DDEC:
    // 0x8002DDEC: b           L_8002DE30
    // 0x8002DDF0: sw          $t8, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r24;
        goto L_8002DE30;
    // 0x8002DDF0: sw          $t8, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r24;
L_8002DDF4:
    // 0x8002DDF4: addiu       $a0, $zero, 0x1
    ctx->r4 = ADD32(0, 0X1);
    // 0x8002DDF8: jal         0x80048B90
    // 0x8002DDFC: sw          $a2, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r6;
    func_80048B90(rdram, ctx);
        goto after_1;
    // 0x8002DDFC: sw          $a2, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r6;
    after_1:
    // 0x8002DE00: lw          $a2, 0x18($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X18);
    // 0x8002DE04: lw          $v1, 0x8($a2)
    ctx->r3 = MEM_W(ctx->r6, 0X8);
    // 0x8002DE08: lw          $v0, 0x4($a2)
    ctx->r2 = MEM_W(ctx->r6, 0X4);
    // 0x8002DE0C: addiu       $t9, $v1, -0x1
    ctx->r25 = ADD32(ctx->r3, -0X1);
    // 0x8002DE10: slt         $at, $v0, $t9
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r25) ? 1 : 0;
    // 0x8002DE14: bne         $at, $zero, L_8002DE24
    if (ctx->r1 != 0) {
        // 0x8002DE18: subu        $t0, $v0, $v1
        ctx->r8 = SUB32(ctx->r2, ctx->r3);
            goto L_8002DE24;
    }
    // 0x8002DE18: subu        $t0, $v0, $v1
    ctx->r8 = SUB32(ctx->r2, ctx->r3);
    // 0x8002DE1C: sw          $t0, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r8;
    // 0x8002DE20: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
L_8002DE24:
    // 0x8002DE24: addiu       $t1, $v0, 0x1
    ctx->r9 = ADD32(ctx->r2, 0X1);
    // 0x8002DE28: sw          $t1, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r9;
    // 0x8002DE2C: addiu       $v1, $zero, 0x1
    ctx->r3 = ADD32(0, 0X1);
L_8002DE30:
    // 0x8002DE30: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x8002DE34: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x8002DE38: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
    // 0x8002DE3C: jr          $ra
    // 0x8002DE40: nop

    return;
    // 0x8002DE40: nop

;}
RECOMP_FUNC void func_80011CF0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80011CF0: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x80011CF4: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x80011CF8: or          $s0, $a1, $zero
    ctx->r16 = ctx->r5 | 0;
    // 0x80011CFC: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x80011D00: sw          $a2, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r6;
    // 0x80011D04: beq         $a0, $zero, L_80011D1C
    if (ctx->r4 == 0) {
        // 0x80011D08: sw          $a3, 0x2C($sp)
        MEM_W(0X2C, ctx->r29) = ctx->r7;
            goto L_80011D1C;
    }
    // 0x80011D08: sw          $a3, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r7;
    // 0x80011D0C: addiu       $a1, $zero, 0x2C
    ctx->r5 = ADD32(0, 0X2C);
    // 0x80011D10: jal         0x80002DCC
    // 0x80011D14: addiu       $a2, $zero, 0x4
    ctx->r6 = ADD32(0, 0X4);
    func_80002DCC(rdram, ctx);
        goto after_0;
    // 0x80011D14: addiu       $a2, $zero, 0x4
    ctx->r6 = ADD32(0, 0X4);
    after_0:
    // 0x80011D18: or          $s0, $v0, $zero
    ctx->r16 = ctx->r2 | 0;
L_80011D1C:
    // 0x80011D1C: beq         $s0, $zero, L_80011D98
    if (ctx->r16 == 0) {
        // 0x80011D20: lh          $t6, 0x2E($sp)
        ctx->r14 = MEM_H(ctx->r29, 0X2E);
            goto L_80011D98;
    }
    // 0x80011D20: lh          $t6, 0x2E($sp)
    ctx->r14 = MEM_H(ctx->r29, 0X2E);
    // 0x80011D24: sh          $t6, 0x1C($s0)
    MEM_H(0X1C, ctx->r16) = ctx->r14;
    // 0x80011D28: lh          $t7, 0x32($sp)
    ctx->r15 = MEM_H(ctx->r29, 0X32);
    // 0x80011D2C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x80011D30: addiu       $a1, $zero, 0x1C
    ctx->r5 = ADD32(0, 0X1C);
    // 0x80011D34: sh          $t7, 0x1E($s0)
    MEM_H(0X1E, ctx->r16) = ctx->r15;
    // 0x80011D38: lh          $t8, 0x36($sp)
    ctx->r24 = MEM_H(ctx->r29, 0X36);
    // 0x80011D3C: sh          $t8, 0x20($s0)
    MEM_H(0X20, ctx->r16) = ctx->r24;
    // 0x80011D40: lh          $t9, 0x3A($sp)
    ctx->r25 = MEM_H(ctx->r29, 0X3A);
    // 0x80011D44: sh          $t9, 0x22($s0)
    MEM_H(0X22, ctx->r16) = ctx->r25;
    // 0x80011D48: lh          $t0, 0x3E($sp)
    ctx->r8 = MEM_H(ctx->r29, 0X3E);
    // 0x80011D4C: sh          $t0, 0x18($s0)
    MEM_H(0X18, ctx->r16) = ctx->r8;
    // 0x80011D50: lh          $t1, 0x42($sp)
    ctx->r9 = MEM_H(ctx->r29, 0X42);
    // 0x80011D54: sh          $t1, 0x1A($s0)
    MEM_H(0X1A, ctx->r16) = ctx->r9;
    // 0x80011D58: lw          $t2, 0x44($sp)
    ctx->r10 = MEM_W(ctx->r29, 0X44);
    // 0x80011D5C: sw          $t2, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r10;
    // 0x80011D60: lbu         $t5, 0x4F($sp)
    ctx->r13 = MEM_BU(ctx->r29, 0X4F);
    // 0x80011D64: lbu         $t3, 0x4B($sp)
    ctx->r11 = MEM_BU(ctx->r29, 0X4B);
    // 0x80011D68: lbu         $t8, 0x53($sp)
    ctx->r24 = MEM_BU(ctx->r29, 0X53);
    // 0x80011D6C: lbu         $t1, 0x57($sp)
    ctx->r9 = MEM_BU(ctx->r29, 0X57);
    // 0x80011D70: sll         $t6, $t5, 16
    ctx->r14 = S32(ctx->r13 << 16);
    // 0x80011D74: sll         $t4, $t3, 24
    ctx->r12 = S32(ctx->r11 << 24);
    // 0x80011D78: or          $t7, $t4, $t6
    ctx->r15 = ctx->r12 | ctx->r14;
    // 0x80011D7C: sll         $t9, $t8, 8
    ctx->r25 = S32(ctx->r24 << 8);
    // 0x80011D80: or          $t0, $t7, $t9
    ctx->r8 = ctx->r15 | ctx->r25;
    // 0x80011D84: or          $t2, $t0, $t1
    ctx->r10 = ctx->r8 | ctx->r9;
    // 0x80011D88: jal         0x80010FA0
    // 0x80011D8C: sw          $t2, 0x28($s0)
    MEM_W(0X28, ctx->r16) = ctx->r10;
    func_80010FA0(rdram, ctx);
        goto after_1;
    // 0x80011D8C: sw          $t2, 0x28($s0)
    MEM_W(0X28, ctx->r16) = ctx->r10;
    after_1:
    // 0x80011D90: lw          $t3, 0x28($sp)
    ctx->r11 = MEM_W(ctx->r29, 0X28);
    // 0x80011D94: sb          $t3, 0x3($s0)
    MEM_B(0X3, ctx->r16) = ctx->r11;
L_80011D98:
    // 0x80011D98: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x80011D9C: or          $v0, $s0, $zero
    ctx->r2 = ctx->r16 | 0;
    // 0x80011DA0: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x80011DA4: jr          $ra
    // 0x80011DA8: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    return;
    // 0x80011DA8: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
;}
RECOMP_FUNC void func_84340230(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84340230: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x84340234: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x84340238: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x8434023C: jal         0x8140C038
    // 0x84340240: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    func_8140C038(rdram, ctx);
        goto after_0;
    // 0x84340240: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    after_0:
    // 0x84340244: lui         $a1, 0x3DF5
    ctx->r5 = S32(0X3DF5 << 16);
    // 0x84340248: sh          $v0, 0x26($sp)
    MEM_H(0X26, ctx->r29) = ctx->r2;
    // 0x8434024C: ori         $a1, $a1, 0xC28F
    ctx->r5 = ctx->r5 | 0XC28F;
    // 0x84340250: jal         0x8140B938
    // 0x84340254: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140B938(rdram, ctx);
        goto after_1;
    // 0x84340254: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_1:
    // 0x84340258: jal         0x81400A78
    // 0x8434025C: addiu       $a0, $zero, 0x14
    ctx->r4 = ADD32(0, 0X14);
    func_81400A78(rdram, ctx);
        goto after_2;
    // 0x8434025C: addiu       $a0, $zero, 0x14
    ctx->r4 = ADD32(0, 0X14);
    after_2:
    // 0x84340260: mtc1        $v0, $f4
    ctx->f4.u32l = ctx->r2;
    // 0x84340264: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84340268: bgez        $v0, L_84340280
    if (SIGNED(ctx->r2) >= 0) {
        // 0x8434026C: cvt.s.w     $f6, $f4
        CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
            goto L_84340280;
    }
    // 0x8434026C: cvt.s.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
    // 0x84340270: lui         $at, 0x4F80
    ctx->r1 = S32(0X4F80 << 16);
    // 0x84340274: mtc1        $at, $f8
    ctx->f8.u32l = ctx->r1;
    // 0x84340278: nop

    // 0x8434027C: add.s       $f6, $f6, $f8
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f8.fl); 
    ctx->f6.fl = ctx->f6.fl + ctx->f8.fl;
L_84340280:
    // 0x84340280: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X8C248) << 16);
    // 0x84340284: lwc1        $f10, -0x3DB8($at)
    ctx->f10.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X8C248));
    // 0x84340288: lui         $at, 0x3E80
    ctx->r1 = S32(0X3E80 << 16);
    // 0x8434028C: mtc1        $at, $f18
    ctx->f18.u32l = ctx->r1;
    // 0x84340290: mul.s       $f16, $f6, $f10
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f16.fl = MUL_S(ctx->f6.fl, ctx->f10.fl);
    // 0x84340294: add.s       $f4, $f16, $f18
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f16.fl); NAN_CHECK(ctx->f18.fl); 
    ctx->f4.fl = ctx->f16.fl + ctx->f18.fl;
    // 0x84340298: mfc1        $a1, $f4
    ctx->r5 = (int32_t)ctx->f4.u32l;
    // 0x8434029C: jal         0x8140AF24
    // 0x843402A0: nop

    func_8140AF24(rdram, ctx);
        goto after_3;
    // 0x843402A0: nop

    after_3:
    // 0x843402A4: jal         0x81400A78
    // 0x843402A8: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    func_81400A78(rdram, ctx);
        goto after_4;
    // 0x843402A8: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    after_4:
    // 0x843402AC: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x843402B0: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x843402B4: jal         0x8140A2A4
    // 0x843402B8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A2A4(rdram, ctx);
        goto after_5;
    // 0x843402B8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_5:
    // 0x843402BC: jal         0x81400A78
    // 0x843402C0: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    func_81400A78(rdram, ctx);
        goto after_6;
    // 0x843402C0: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    after_6:
    // 0x843402C4: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x843402C8: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x843402CC: jal         0x8140A2CC
    // 0x843402D0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A2CC(rdram, ctx);
        goto after_7;
    // 0x843402D0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_7:
    // 0x843402D4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x843402D8: jal         0x8140AD8C
    // 0x843402DC: lui         $a1, 0x40A0
    ctx->r5 = S32(0X40A0 << 16);
    func_8140AD8C(rdram, ctx);
        goto after_8;
    // 0x843402DC: lui         $a1, 0x40A0
    ctx->r5 = S32(0X40A0 << 16);
    after_8:
    // 0x843402E0: jal         0x81400A78
    // 0x843402E4: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    func_81400A78(rdram, ctx);
        goto after_9;
    // 0x843402E4: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    after_9:
    // 0x843402E8: addiu       $a1, $v0, 0xC00
    ctx->r5 = ADD32(ctx->r2, 0XC00);
    // 0x843402EC: sll         $a1, $a1, 16
    ctx->r5 = S32(ctx->r5 << 16);
    // 0x843402F0: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x843402F4: jal         0x8140BF4C
    // 0x843402F8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140BF4C(rdram, ctx);
        goto after_10;
    // 0x843402F8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_10:
    // 0x843402FC: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    // 0x84340300: jal         0x81400B4C
    // 0x84340304: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    func_81400B4C(rdram, ctx);
        goto after_11;
    // 0x84340304: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    after_11:
    // 0x84340308: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x8434030C: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x84340310: jal         0x8140A3C4
    // 0x84340314: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A3C4(rdram, ctx);
        goto after_12;
    // 0x84340314: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_12:
    // 0x84340318: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    // 0x8434031C: jal         0x81400B4C
    // 0x84340320: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    func_81400B4C(rdram, ctx);
        goto after_13;
    // 0x84340320: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    after_13:
    // 0x84340324: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x84340328: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x8434032C: jal         0x8140BFEC
    // 0x84340330: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140BFEC(rdram, ctx);
        goto after_14;
    // 0x84340330: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_14:
    // 0x84340334: jal         0x81400A78
    // 0x84340338: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    func_81400A78(rdram, ctx);
        goto after_15;
    // 0x84340338: lui         $a0, 0x1
    ctx->r4 = S32(0X1 << 16);
    after_15:
    // 0x8434033C: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x84340340: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x84340344: jal         0x8140A3D8
    // 0x84340348: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A3D8(rdram, ctx);
        goto after_16;
    // 0x84340348: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_16:
    // 0x8434034C: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    // 0x84340350: jal         0x81400B4C
    // 0x84340354: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    func_81400B4C(rdram, ctx);
        goto after_17;
    // 0x84340354: addiu       $a1, $zero, 0x300
    ctx->r5 = ADD32(0, 0X300);
    after_17:
    // 0x84340358: sll         $a1, $v0, 16
    ctx->r5 = S32(ctx->r2 << 16);
    // 0x8434035C: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x84340360: jal         0x8140A3EC
    // 0x84340364: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8140A3EC(rdram, ctx);
        goto after_18;
    // 0x84340364: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_18:
    // 0x84340368: jal         0x81400A78
    // 0x8434036C: addiu       $a0, $zero, 0x1E
    ctx->r4 = ADD32(0, 0X1E);
    func_81400A78(rdram, ctx);
        goto after_19;
    // 0x8434036C: addiu       $a0, $zero, 0x1E
    ctx->r4 = ADD32(0, 0X1E);
    after_19:
    // 0x84340370: mtc1        $v0, $f8
    ctx->f8.u32l = ctx->r2;
    // 0x84340374: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x84340378: bgez        $v0, L_84340390
    if (SIGNED(ctx->r2) >= 0) {
        // 0x8434037C: cvt.s.w     $f8, $f8
        CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 8);
    ctx->f8.fl = CVT_S_W(ctx->f8.u32l);
            goto L_84340390;
    }
    // 0x8434037C: cvt.s.w     $f8, $f8
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 8);
    ctx->f8.fl = CVT_S_W(ctx->f8.u32l);
    // 0x84340380: lui         $at, 0x4F80
    ctx->r1 = S32(0X4F80 << 16);
    // 0x84340384: mtc1        $at, $f6
    ctx->f6.u32l = ctx->r1;
    // 0x84340388: nop

    // 0x8434038C: add.s       $f8, $f8, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f6.fl); 
    ctx->f8.fl = ctx->f8.fl + ctx->f6.fl;
L_84340390:
    // 0x84340390: mfc1        $a1, $f8
    ctx->r5 = (int32_t)ctx->f8.u32l;
    // 0x84340394: jal         0x81408E90
    // 0x84340398: nop

    func_81408E90(rdram, ctx);
        goto after_20;
    // 0x84340398: nop

    after_20:
    // 0x8434039C: lh          $a1, 0x26($sp)
    ctx->r5 = MEM_H(ctx->r29, 0X26);
    // 0x843403A0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x843403A4: sll         $a1, $a1, 1
    ctx->r5 = S32(ctx->r5 << 1);
    // 0x843403A8: sll         $a1, $a1, 16
    ctx->r5 = S32(ctx->r5 << 16);
    // 0x843403AC: jal         0x8140BCA8
    // 0x843403B0: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    func_8140BCA8(rdram, ctx);
        goto after_21;
    // 0x843403B0: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    after_21:
    // 0x843403B4: jal         0x81408348
    // 0x843403B8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_81408348(rdram, ctx);
        goto after_22;
    // 0x843403B8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_22:
    // 0x843403BC: jal         0x814081BC
    // 0x843403C0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_814081BC(rdram, ctx);
        goto after_23;
    // 0x843403C0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_23:
    // 0x843403C4: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x843403C8: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x843403CC: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x843403D0: jr          $ra
    // 0x843403D4: nop

    return;
    // 0x843403D4: nop

;}
RECOMP_FUNC void func_8431E4DC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8431E4DC: addiu       $sp, $sp, -0x38
    ctx->r29 = ADD32(ctx->r29, -0X38);
    // 0x8431E4E0: sw          $s1, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r17;
    // 0x8431E4E4: or          $s1, $a0, $zero
    ctx->r17 = ctx->r4 | 0;
    // 0x8431E4E8: sw          $s0, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r16;
    // 0x8431E4EC: or          $s0, $a1, $zero
    ctx->r16 = ctx->r5 | 0;
    // 0x8431E4F0: or          $a0, $a1, $zero
    ctx->r4 = ctx->r5 | 0;
    // 0x8431E4F4: lui         $a1, 0x8439
    ctx->r5 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431E4F8: lw          $a1, 0x240($a1)
    ctx->r5 = MEM_W(ctx->r5, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431E4FC: sw          $ra, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r31;
    // 0x8431E500: sw          $a2, 0x40($sp)
    MEM_W(0X40, ctx->r29) = ctx->r6;
    // 0x8431E504: jal         0x843081F0
    // 0x8431E508: addiu       $a1, $a1, 0xD0
    ctx->r5 = ADD32(ctx->r5, 0XD0);
    func_843081F0(rdram, ctx);
        goto after_0;
    // 0x8431E508: addiu       $a1, $a1, 0xD0
    ctx->r5 = ADD32(ctx->r5, 0XD0);
    after_0:
    // 0x8431E50C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8431E510: lui         $a1, 0x3F00
    ctx->r5 = S32(0X3F00 << 16);
    // 0x8431E514: jal         0x8431AD20
    // 0x8431E518: lui         $a2, 0x42C8
    ctx->r6 = S32(0X42C8 << 16);
    func_8431AD20(rdram, ctx);
        goto after_1;
    // 0x8431E518: lui         $a2, 0x42C8
    ctx->r6 = S32(0X42C8 << 16);
    after_1:
    // 0x8431E51C: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X901F0) << 16);
    // 0x8431E520: swc1        $f0, 0x1F0($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X901F0), ctx->r1) = ctx->f0.u32l;
    // 0x8431E524: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8431E528: lui         $a1, 0x40A0
    ctx->r5 = S32(0X40A0 << 16);
    // 0x8431E52C: jal         0x8431AD20
    // 0x8431E530: lui         $a2, 0x4396
    ctx->r6 = S32(0X4396 << 16);
    func_8431AD20(rdram, ctx);
        goto after_2;
    // 0x8431E530: lui         $a2, 0x4396
    ctx->r6 = S32(0X4396 << 16);
    after_2:
    // 0x8431E534: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X901F4) << 16);
    // 0x8431E538: swc1        $f0, 0x1F4($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X901F4), ctx->r1) = ctx->f0.u32l;
    // 0x8431E53C: jal         0x84308190
    // 0x8431E540: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84308190(rdram, ctx);
        goto after_3;
    // 0x8431E540: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_3:
    // 0x8431E544: lui         $t6, 0x8439
    ctx->r14 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431E548: lw          $t6, 0x240($t6)
    ctx->r14 = MEM_W(ctx->r14, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431E54C: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X901F0) << 16);
    // 0x8431E550: lwc1        $f4, 0x1F0($at)
    ctx->f4.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X901F0));
    // 0x8431E554: lw          $t8, 0xD0($t6)
    ctx->r24 = MEM_W(ctx->r14, 0XD0);
    // 0x8431E558: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x8431E55C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8431E560: sw          $t8, 0x8($sp)
    MEM_W(0X8, ctx->r29) = ctx->r24;
    // 0x8431E564: lw          $a3, 0xD4($t6)
    ctx->r7 = MEM_W(ctx->r14, 0XD4);
    // 0x8431E568: lw          $a2, 0x8($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X8);
    // 0x8431E56C: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x8431E570: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    // 0x8431E574: lw          $t8, 0xD8($t6)
    ctx->r24 = MEM_W(ctx->r14, 0XD8);
    // 0x8431E578: sw          $v0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r2;
    // 0x8431E57C: sw          $zero, 0x14($sp)
    MEM_W(0X14, ctx->r29) = 0;
    // 0x8431E580: swc1        $f4, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f4.u32l;
    // 0x8431E584: swc1        $f6, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->f6.u32l;
    // 0x8431E588: jal         0x8431BAB4
    // 0x8431E58C: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    func_8431BAB4(rdram, ctx);
        goto after_4;
    // 0x8431E58C: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    after_4:
    // 0x8431E590: jal         0x84308190
    // 0x8431E594: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84308190(rdram, ctx);
        goto after_5;
    // 0x8431E594: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_5:
    // 0x8431E598: lui         $t9, 0x8439
    ctx->r25 = S32(RELOC_HI16(259, 0X90240) << 16);
    // 0x8431E59C: lw          $t9, 0x240($t9)
    ctx->r25 = MEM_W(ctx->r25, (int16_t)RELOC_LO16(259, 0X90240));
    // 0x8431E5A0: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X901F4) << 16);
    // 0x8431E5A4: lwc1        $f8, 0x1F4($at)
    ctx->f8.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(259, 0X901F4));
    // 0x8431E5A8: lw          $t1, 0xD0($t9)
    ctx->r9 = MEM_W(ctx->r25, 0XD0);
    // 0x8431E5AC: mtc1        $zero, $f10
    ctx->f10.u32l = 0;
    // 0x8431E5B0: addiu       $t2, $zero, 0xE38
    ctx->r10 = ADD32(0, 0XE38);
    // 0x8431E5B4: sw          $t1, 0x4($sp)
    MEM_W(0X4, ctx->r29) = ctx->r9;
    // 0x8431E5B8: lw          $a2, 0xD4($t9)
    ctx->r6 = MEM_W(ctx->r25, 0XD4);
    // 0x8431E5BC: lw          $a1, 0x4($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4);
    // 0x8431E5C0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x8431E5C4: sw          $a2, 0x8($sp)
    MEM_W(0X8, ctx->r29) = ctx->r6;
    // 0x8431E5C8: lw          $a3, 0xD8($t9)
    ctx->r7 = MEM_W(ctx->r25, 0XD8);
    // 0x8431E5CC: sw          $v0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r2;
    // 0x8431E5D0: sw          $t2, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r10;
    // 0x8431E5D4: swc1        $f8, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->f8.u32l;
    // 0x8431E5D8: swc1        $f10, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->f10.u32l;
    // 0x8431E5DC: jal         0x8431BB80
    // 0x8431E5E0: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    func_8431BB80(rdram, ctx);
        goto after_6;
    // 0x8431E5E0: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    after_6:
    // 0x8431E5E4: lw          $t3, 0x40($sp)
    ctx->r11 = MEM_W(ctx->r29, 0X40);
    // 0x8431E5E8: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8431E5EC: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x8431E5F0: bne         $t3, $at, L_8431E608
    if (ctx->r11 != ctx->r1) {
        // 0x8431E5F4: or          $a0, $s1, $zero
        ctx->r4 = ctx->r17 | 0;
            goto L_8431E608;
    }
    // 0x8431E5F4: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x8431E5F8: jal         0x8431B858
    // 0x8431E5FC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_8431B858(rdram, ctx);
        goto after_7;
    // 0x8431E5FC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_7:
    // 0x8431E600: b           L_8431E620
    // 0x8431E604: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
        goto L_8431E620;
    // 0x8431E604: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
L_8431E608:
    // 0x8431E608: jal         0x8431C71C
    // 0x8431E60C: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    func_8431C71C(rdram, ctx);
        goto after_8;
    // 0x8431E60C: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    after_8:
    // 0x8431E610: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x8431E614: jal         0x8431C71C
    // 0x8431E618: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    func_8431C71C(rdram, ctx);
        goto after_9;
    // 0x8431E618: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    after_9:
    // 0x8431E61C: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
L_8431E620:
    // 0x8431E620: jal         0x8431C71C
    // 0x8431E624: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    func_8431C71C(rdram, ctx);
        goto after_10;
    // 0x8431E624: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    after_10:
    // 0x8431E628: lw          $ra, 0x34($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X34);
    // 0x8431E62C: lw          $s0, 0x2C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X2C);
    // 0x8431E630: lw          $s1, 0x30($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X30);
    // 0x8431E634: jr          $ra
    // 0x8431E638: addiu       $sp, $sp, 0x38
    ctx->r29 = ADD32(ctx->r29, 0X38);
    return;
    // 0x8431E638: addiu       $sp, $sp, 0x38
    ctx->r29 = ADD32(ctx->r29, 0X38);
;}
RECOMP_FUNC void func_868026B8(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x868026B8: sw          $a0, 0x0($sp)
    MEM_W(0X0, ctx->r29) = ctx->r4;
    // 0x868026BC: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x868026C0: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    // 0x868026C4: slti        $at, $a0, 0x32
    ctx->r1 = SIGNED(ctx->r4) < 0X32 ? 1 : 0;
    // 0x868026C8: beq         $at, $zero, L_868026D8
    if (ctx->r1 == 0) {
        // 0x868026CC: addiu       $v1, $zero, 0x1
        ctx->r3 = ADD32(0, 0X1);
            goto L_868026D8;
    }
    // 0x868026CC: addiu       $v1, $zero, 0x1
    ctx->r3 = ADD32(0, 0X1);
    // 0x868026D0: jr          $ra
    // 0x868026D4: addiu       $v0, $zero, 0x2
    ctx->r2 = ADD32(0, 0X2);
    return;
    // 0x868026D4: addiu       $v0, $zero, 0x2
    ctx->r2 = ADD32(0, 0X2);
L_868026D8:
    // 0x868026D8: jr          $ra
    // 0x868026DC: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
    return;
    // 0x868026DC: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
;}
RECOMP_FUNC void func_84306584(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84306584: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x84306588: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x8430658C: lhu         $t6, 0x688($a0)
    ctx->r14 = MEM_HU(ctx->r4, 0X688);
    // 0x84306590: andi        $t7, $t6, 0x8
    ctx->r15 = ctx->r14 & 0X8;
    // 0x84306594: beql        $t7, $zero, L_843065B8
    if (ctx->r15 == 0) {
        // 0x84306598: lw          $ra, 0x14($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X14);
            goto L_843065B8;
    }
    goto skip_0;
    // 0x84306598: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    skip_0:
    // 0x8430659C: jal         0x84307BAC
    // 0x843065A0: sw          $a0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r4;
    func_84307BAC(rdram, ctx);
        goto after_0;
    // 0x843065A0: sw          $a0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r4;
    after_0:
    // 0x843065A4: lw          $a0, 0x18($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X18);
    // 0x843065A8: addiu       $a1, $zero, 0x608
    ctx->r5 = ADD32(0, 0X608);
    // 0x843065AC: jal         0x84306200
    // 0x843065B0: swc1        $f0, 0x28($a0)
    MEM_W(0X28, ctx->r4) = ctx->f0.u32l;
    func_84306200(rdram, ctx);
        goto after_1;
    // 0x843065B0: swc1        $f0, 0x28($a0)
    MEM_W(0X28, ctx->r4) = ctx->f0.u32l;
    after_1:
    // 0x843065B4: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_843065B8:
    // 0x843065B8: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x843065BC: jr          $ra
    // 0x843065C0: nop

    return;
    // 0x843065C0: nop

;}
RECOMP_FUNC void func_883003E4(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x883003E4: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x883003E8: or          $a3, $a0, $zero
    ctx->r7 = ctx->r4 | 0;
    // 0x883003EC: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x883003F0: lui         $a0, 0x8850
    ctx->r4 = S32(RELOC_HI16(111, 0X7CC) << 16);
    // 0x883003F4: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    // 0x883003F8: sw          $a2, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r6;
    // 0x883003FC: addiu       $a0, $a0, 0x7CC
    ctx->r4 = ADD32(ctx->r4, (int16_t)RELOC_LO16(111, 0X7CC));
    // 0x88300400: jal         0x800020E0
    // 0x88300404: sw          $a3, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r7;
    Memmap_GetFragmentVaddr(rdram, ctx);
        goto after_0;
    // 0x88300404: sw          $a3, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r7;
    after_0:
    // 0x88300408: lw          $a0, 0x18($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X18);
    // 0x8830040C: jalr        $v0
    // 0x88300410: addiu       $a1, $zero, 0x2C
    ctx->r5 = ADD32(0, 0X2C);
    LOOKUP_FUNC(ctx->r2)(rdram, ctx);
        goto after_1;
    // 0x88300410: addiu       $a1, $zero, 0x2C
    ctx->r5 = ADD32(0, 0X2C);
    after_1:
    // 0x88300414: lw          $a3, 0x18($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X18);
    // 0x88300418: lui         $t6, 0x8830
    ctx->r14 = S32(RELOC_HI16(103, 0X454) << 16);
    // 0x8830041C: addiu       $t6, $t6, 0x454
    ctx->r14 = ADD32(ctx->r14, (int16_t)RELOC_LO16(103, 0X454));
    // 0x88300420: sw          $t6, 0x18($a3)
    MEM_W(0X18, ctx->r7) = ctx->r14;
    // 0x88300424: lw          $t7, 0x1C($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X1C);
    // 0x88300428: addiu       $t9, $zero, 0x5C
    ctx->r25 = ADD32(0, 0X5C);
    // 0x8830042C: addiu       $t0, $zero, 0x14
    ctx->r8 = ADD32(0, 0X14);
    // 0x88300430: sh          $t7, 0x10($a3)
    MEM_H(0X10, ctx->r7) = ctx->r15;
    // 0x88300434: lw          $t8, 0x20($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X20);
    // 0x88300438: sh          $t0, 0x16($a3)
    MEM_H(0X16, ctx->r7) = ctx->r8;
    // 0x8830043C: sh          $t9, 0x14($a3)
    MEM_H(0X14, ctx->r7) = ctx->r25;
    // 0x88300440: sh          $t8, 0x12($a3)
    MEM_H(0X12, ctx->r7) = ctx->r24;
    // 0x88300444: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x88300448: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x8830044C: jr          $ra
    // 0x88300450: nop

    return;
    // 0x88300450: nop

;}
RECOMP_FUNC void func_86A01490(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86A01490: lui         $v1, 0x86A0
    ctx->r3 = S32(RELOC_HI16(71, 0X6212) << 16);
    // 0x86A01494: addiu       $v1, $v1, 0x6212
    ctx->r3 = ADD32(ctx->r3, (int16_t)RELOC_LO16(71, 0X6212));
    // 0x86A01498: lbu         $t6, 0x0($v1)
    ctx->r14 = MEM_BU(ctx->r3, 0X0);
    // 0x86A0149C: lui         $v0, 0x800A
    ctx->r2 = S32(0X800A << 16);
    // 0x86A014A0: lw          $v0, 0x6D14($v0)
    ctx->r2 = MEM_W(ctx->r2, 0X6D14);
    // 0x86A014A4: bne         $t6, $zero, L_86A014B4
    if (ctx->r14 != 0) {
        // 0x86A014A8: addiu       $t7, $zero, 0x1
        ctx->r15 = ADD32(0, 0X1);
            goto L_86A014B4;
    }
    // 0x86A014A8: addiu       $t7, $zero, 0x1
    ctx->r15 = ADD32(0, 0X1);
    // 0x86A014AC: b           L_86A014E4
    // 0x86A014B0: sb          $t7, 0x0($v1)
    MEM_B(0X0, ctx->r3) = ctx->r15;
        goto L_86A014E4;
    // 0x86A014B0: sb          $t7, 0x0($v1)
    MEM_B(0X0, ctx->r3) = ctx->r15;
L_86A014B4:
    // 0x86A014B4: lui         $v1, 0x86A0
    ctx->r3 = S32(RELOC_HI16(71, 0X621C) << 16);
    // 0x86A014B8: lw          $v1, 0x621C($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(71, 0X621C));
    // 0x86A014BC: sltu        $at, $v1, $v0
    ctx->r1 = ctx->r3 < ctx->r2 ? 1 : 0;
    // 0x86A014C0: beq         $at, $zero, L_86A014D4
    if (ctx->r1 == 0) {
        // 0x86A014C4: subu        $t8, $v0, $v1
        ctx->r24 = SUB32(ctx->r2, ctx->r3);
            goto L_86A014D4;
    }
    // 0x86A014C4: subu        $t8, $v0, $v1
    ctx->r24 = SUB32(ctx->r2, ctx->r3);
    // 0x86A014C8: lui         $at, 0x86A0
    ctx->r1 = S32(RELOC_HI16(71, 0X6210) << 16);
    // 0x86A014CC: b           L_86A014E4
    // 0x86A014D0: sb          $t8, 0x6210($at)
    MEM_B((int16_t)RELOC_LO16(71, 0X6210), ctx->r1) = ctx->r24;
        goto L_86A014E4;
    // 0x86A014D0: sb          $t8, 0x6210($at)
    MEM_B((int16_t)RELOC_LO16(71, 0X6210), ctx->r1) = ctx->r24;
L_86A014D4:
    // 0x86A014D4: addiu       $t5, $v0, 0x0
    ctx->r13 = ADD32(ctx->r2, 0X0);
    // 0x86A014D8: subu        $t9, $t5, $v1
    ctx->r25 = SUB32(ctx->r13, ctx->r3);
    // 0x86A014DC: lui         $at, 0x86A0
    ctx->r1 = S32(RELOC_HI16(71, 0X6210) << 16);
    // 0x86A014E0: sb          $t9, 0x6210($at)
    MEM_B((int16_t)RELOC_LO16(71, 0X6210), ctx->r1) = ctx->r25;
L_86A014E4:
    // 0x86A014E4: lui         $at, 0x86A0
    ctx->r1 = S32(RELOC_HI16(71, 0X621C) << 16);
    // 0x86A014E8: jr          $ra
    // 0x86A014EC: sw          $v0, 0x621C($at)
    MEM_W((int16_t)RELOC_LO16(71, 0X621C), ctx->r1) = ctx->r2;
    return;
    // 0x86A014EC: sw          $v0, 0x621C($at)
    MEM_W((int16_t)RELOC_LO16(71, 0X621C), ctx->r1) = ctx->r2;
;}
RECOMP_FUNC void func_86502110(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86502110: addiu       $sp, $sp, -0xC8
    ctx->r29 = ADD32(ctx->r29, -0XC8);
    // 0x86502114: sw          $ra, 0x44($sp)
    MEM_W(0X44, ctx->r29) = ctx->r31;
    // 0x86502118: sw          $a0, 0xC8($sp)
    MEM_W(0XC8, ctx->r29) = ctx->r4;
    // 0x8650211C: sw          $fp, 0x40($sp)
    MEM_W(0X40, ctx->r29) = ctx->r30;
    // 0x86502120: sw          $s7, 0x3C($sp)
    MEM_W(0X3C, ctx->r29) = ctx->r23;
    // 0x86502124: sw          $s6, 0x38($sp)
    MEM_W(0X38, ctx->r29) = ctx->r22;
    // 0x86502128: sw          $s5, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r21;
    // 0x8650212C: sw          $s4, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r20;
    // 0x86502130: sw          $s3, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r19;
    // 0x86502134: sw          $s2, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r18;
    // 0x86502138: sw          $s1, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r17;
    // 0x8650213C: sw          $s0, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r16;
    // 0x86502140: sdc1        $f20, 0x18($sp)
    CHECK_FR(ctx, 20);
    SD(ctx->f20.u64, 0X18, ctx->r29);
    // 0x86502144: jal         0x80005F5C
    // 0x86502148: addiu       $a0, $zero, 0xC00
    ctx->r4 = ADD32(0, 0XC00);
    func_80005F5C(rdram, ctx);
        goto after_0;
    // 0x86502148: addiu       $a0, $zero, 0xC00
    ctx->r4 = ADD32(0, 0XC00);
    after_0:
    // 0x8650214C: lui         $t6, 0x8651
    ctx->r14 = S32(RELOC_HI16(51, 0X8F50) << 16);
    // 0x86502150: addiu       $t6, $t6, -0x70B0
    ctx->r14 = ADD32(ctx->r14, (int16_t)RELOC_LO16(51, 0X8F50));
    // 0x86502154: lui         $s7, 0x8781
    ctx->r23 = S32(RELOC_HI16(14, 0XFC94) << 16);
    // 0x86502158: lui         $s3, 0x8651
    ctx->r19 = S32(RELOC_HI16(51, 0XAD70) << 16);
    // 0x8650215C: mtc1        $zero, $f20
    ctx->f20.u32l = 0;
    // 0x86502160: or          $s4, $v0, $zero
    ctx->r20 = ctx->r2 | 0;
    // 0x86502164: addiu       $s3, $s3, -0x5290
    ctx->r19 = ADD32(ctx->r19, (int16_t)RELOC_LO16(51, 0XAD70));
    // 0x86502168: addiu       $s7, $s7, -0x36C
    ctx->r23 = ADD32(ctx->r23, (int16_t)RELOC_LO16(14, 0XFC94));
    // 0x8650216C: sw          $t6, 0x54($sp)
    MEM_W(0X54, ctx->r29) = ctx->r14;
    // 0x86502170: sb          $zero, 0xC7($sp)
    MEM_B(0XC7, ctx->r29) = 0;
    // 0x86502174: lui         $fp, 0xFD90
    ctx->r30 = S32(0XFD90 << 16);
    // 0x86502178: addiu       $s6, $zero, 0xC
    ctx->r22 = ADD32(0, 0XC);
    // 0x8650217C: addiu       $s5, $zero, -0x1
    ctx->r21 = ADD32(0, -0X1);
L_86502180:
    // 0x86502180: lbu         $v1, 0xC7($sp)
    ctx->r3 = MEM_BU(ctx->r29, 0XC7);
    // 0x86502184: lui         $t8, 0x8651
    ctx->r24 = S32(RELOC_HI16(51, 0XA528) << 16);
    // 0x86502188: addiu       $t8, $t8, -0x5AD8
    ctx->r24 = ADD32(ctx->r24, (int16_t)RELOC_LO16(51, 0XA528));
    // 0x8650218C: sll         $t7, $v1, 2
    ctx->r15 = S32(ctx->r3 << 2);
    // 0x86502190: subu        $t7, $t7, $v1
    ctx->r15 = SUB32(ctx->r15, ctx->r3);
    // 0x86502194: sll         $t2, $v1, 3
    ctx->r10 = S32(ctx->r3 << 3);
    // 0x86502198: sll         $t7, $t7, 7
    ctx->r15 = S32(ctx->r15 << 7);
    // 0x8650219C: lui         $t3, 0x8651
    ctx->r11 = S32(RELOC_HI16(51, 0XAB30) << 16);
    // 0x865021A0: addu        $t2, $t2, $v1
    ctx->r10 = ADD32(ctx->r10, ctx->r3);
    // 0x865021A4: addu        $t9, $t7, $t8
    ctx->r25 = ADD32(ctx->r15, ctx->r24);
    // 0x865021A8: lui         $at, 0x8651
    ctx->r1 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x865021AC: sll         $t2, $t2, 4
    ctx->r10 = S32(ctx->r10 << 4);
    // 0x865021B0: addiu       $t3, $t3, -0x54D0
    ctx->r11 = ADD32(ctx->r11, (int16_t)RELOC_LO16(51, 0XAB30));
    // 0x865021B4: sw          $t9, -0x54D8($at)
    MEM_W((int16_t)RELOC_LO16(51, 0XAB28), ctx->r1) = ctx->r25;
    // 0x865021B8: addu        $t4, $t2, $t3
    ctx->r12 = ADD32(ctx->r10, ctx->r11);
    // 0x865021BC: sw          $t4, 0x0($s3)
    MEM_W(0X0, ctx->r19) = ctx->r12;
    // 0x865021C0: jal         0x80005F5C
    // 0x865021C4: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    func_80005F5C(rdram, ctx);
        goto after_1;
    // 0x865021C4: addiu       $a0, $zero, 0x800
    ctx->r4 = ADD32(0, 0X800);
    after_1:
    // 0x865021C8: lui         $t5, 0x8651
    ctx->r13 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x865021CC: lw          $t5, -0x54D8($t5)
    ctx->r13 = MEM_W(ctx->r13, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x865021D0: lui         $t7, 0xDE00
    ctx->r15 = S32(0XDE00 << 16);
    // 0x865021D4: lui         $a0, 0x87B0
    ctx->r4 = S32(RELOC_HI16(26, 0XC8) << 16);
    // 0x865021D8: lw          $t6, 0x17C($t5)
    ctx->r14 = MEM_W(ctx->r13, 0X17C);
    // 0x865021DC: lui         $t3, 0x8651
    ctx->r11 = S32(RELOC_HI16(51, 0X9190) << 16);
    // 0x865021E0: addiu       $s1, $v0, 0x8
    ctx->r17 = ADD32(ctx->r2, 0X8);
    // 0x865021E4: sw          $v0, 0x18($t6)
    MEM_W(0X18, ctx->r14) = ctx->r2;
    // 0x865021E8: sw          $t7, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r15;
    // 0x865021EC: lw          $t8, 0x54($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X54);
    // 0x865021F0: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x865021F4: addiu       $t3, $t3, -0x6E70
    ctx->r11 = ADD32(ctx->r11, (int16_t)RELOC_LO16(51, 0X9190));
    // 0x865021F8: sw          $t8, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r24;
    // 0x865021FC: lbu         $a0, 0xC8($a0)
    ctx->r4 = MEM_BU(ctx->r4, (int16_t)RELOC_LO16(26, 0XC8));
    // 0x86502200: beq         $a0, $zero, L_86502228
    if (ctx->r4 == 0) {
        // 0x86502204: nop
    
            goto L_86502228;
    }
    // 0x86502204: nop

    // 0x86502208: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x8650220C: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x86502210: lbu         $t9, 0xC($v1)
    ctx->r25 = MEM_BU(ctx->r3, 0XC);
    // 0x86502214: bnel        $t9, $at, L_865027F4
    if (ctx->r25 != ctx->r1) {
        // 0x86502218: lbu         $v1, 0xC7($sp)
        ctx->r3 = MEM_BU(ctx->r29, 0XC7);
            goto L_865027F4;
    }
    goto skip_0;
    // 0x86502218: lbu         $v1, 0xC7($sp)
    ctx->r3 = MEM_BU(ctx->r29, 0XC7);
    skip_0:
    // 0x8650221C: lw          $t2, 0x8($v1)
    ctx->r10 = MEM_W(ctx->r3, 0X8);
    // 0x86502220: addiu       $at, $zero, 0x6
    ctx->r1 = ADD32(0, 0X6);
    // 0x86502224: beq         $t2, $at, L_865027F0
    if (ctx->r10 == ctx->r1) {
        // 0x86502228: lui         $v1, 0x8651
        ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
            goto L_865027F0;
    }
L_86502228:
    // 0x86502228: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x8650222C: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x86502230: bne         $a0, $zero, L_8650233C
    if (ctx->r4 != 0) {
        // 0x86502234: sw          $t3, 0x4C($sp)
        MEM_W(0X4C, ctx->r29) = ctx->r11;
            goto L_8650233C;
    }
    // 0x86502234: sw          $t3, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r11;
    // 0x86502238: lh          $t4, 0x10($v1)
    ctx->r12 = MEM_H(ctx->r3, 0X10);
    // 0x8650223C: lh          $t5, 0x12($v1)
    ctx->r13 = MEM_H(ctx->r3, 0X12);
    // 0x86502240: lui         $at, 0x42C8
    ctx->r1 = S32(0X42C8 << 16);
    // 0x86502244: mtc1        $t4, $f4
    ctx->f4.u32l = ctx->r12;
    // 0x86502248: mtc1        $at, $f8
    ctx->f8.u32l = ctx->r1;
    // 0x8650224C: mtc1        $t5, $f16
    ctx->f16.u32l = ctx->r13;
    // 0x86502250: cvt.s.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
    // 0x86502254: lui         $at, 0xBF00
    ctx->r1 = S32(0XBF00 << 16);
    // 0x86502258: cvt.s.w     $f18, $f16
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 16);
    ctx->f18.fl = CVT_S_W(ctx->f16.u32l);
    // 0x8650225C: mul.s       $f10, $f6, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f8.fl); 
    ctx->f10.fl = MUL_S(ctx->f6.fl, ctx->f8.fl);
    // 0x86502260: div.s       $f0, $f10, $f18
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f18.fl); 
    ctx->f0.fl = DIV_S(ctx->f10.fl, ctx->f18.fl);
    // 0x86502264: c.lt.s      $f20, $f0
    CHECK_FR(ctx, 20);
    CHECK_FR(ctx, 0);
    c1cs = ctx->f20.fl < ctx->f0.fl;
    // 0x86502268: nop

    // 0x8650226C: bc1fl       L_86502288
    if (!c1cs) {
        // 0x86502270: mtc1        $at, $f2
        ctx->f2.u32l = ctx->r1;
            goto L_86502288;
    }
    goto skip_1;
    // 0x86502270: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    skip_1:
    // 0x86502274: lui         $at, 0x3F00
    ctx->r1 = S32(0X3F00 << 16);
    // 0x86502278: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x8650227C: b           L_86502290
    // 0x86502280: add.s       $f4, $f2, $f0
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f2.fl); NAN_CHECK(ctx->f0.fl); 
    ctx->f4.fl = ctx->f2.fl + ctx->f0.fl;
        goto L_86502290;
    // 0x86502280: add.s       $f4, $f2, $f0
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f2.fl); NAN_CHECK(ctx->f0.fl); 
    ctx->f4.fl = ctx->f2.fl + ctx->f0.fl;
    // 0x86502284: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
L_86502288:
    // 0x86502288: nop

    // 0x8650228C: add.s       $f4, $f2, $f0
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f2.fl); NAN_CHECK(ctx->f0.fl); 
    ctx->f4.fl = ctx->f2.fl + ctx->f0.fl;
L_86502290:
    // 0x86502290: lui         $at, 0x437A
    ctx->r1 = S32(0X437A << 16);
    // 0x86502294: mtc1        $at, $f10
    ctx->f10.u32l = ctx->r1;
    // 0x86502298: lw          $t8, 0x17C($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X17C);
    // 0x8650229C: trunc.w.s   $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.u32l = TRUNC_W_S(ctx->f4.fl);
    // 0x865022A0: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x865022A4: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x865022A8: mfc1        $t7, $f6
    ctx->r15 = (int32_t)ctx->f6.u32l;
    // 0x865022AC: nop

    // 0x865022B0: mtc1        $t7, $f8
    ctx->f8.u32l = ctx->r15;
    // 0x865022B4: nop

    // 0x865022B8: cvt.s.w     $f16, $f8
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 8);
    ctx->f16.fl = CVT_S_W(ctx->f8.u32l);
    // 0x865022BC: div.s       $f18, $f16, $f10
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f16.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f18.fl = DIV_S(ctx->f16.fl, ctx->f10.fl);
    // 0x865022C0: swc1        $f18, 0x28($t8)
    MEM_W(0X28, ctx->r24) = ctx->f18.u32l;
    // 0x865022C4: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x865022C8: lw          $v0, 0x4($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X4);
    // 0x865022CC: bne         $v0, $zero, L_865022F4
    if (ctx->r2 != 0) {
        // 0x865022D0: nop
    
            goto L_865022F4;
    }
    // 0x865022D0: nop

    // 0x865022D4: lw          $t9, 0x17C($v1)
    ctx->r25 = MEM_W(ctx->r3, 0X17C);
    // 0x865022D8: lw          $t3, 0x100($v1)
    ctx->r11 = MEM_W(ctx->r3, 0X100);
    // 0x865022DC: sw          $t3, 0x1C($t9)
    MEM_W(0X1C, ctx->r25) = ctx->r11;
    // 0x865022E0: lw          $t2, 0x104($v1)
    ctx->r10 = MEM_W(ctx->r3, 0X104);
    // 0x865022E4: sw          $t2, 0x20($t9)
    MEM_W(0X20, ctx->r25) = ctx->r10;
    // 0x865022E8: lw          $t3, 0x108($v1)
    ctx->r11 = MEM_W(ctx->r3, 0X108);
    // 0x865022EC: b           L_86502450
    // 0x865022F0: sw          $t3, 0x24($t9)
    MEM_W(0X24, ctx->r25) = ctx->r11;
        goto L_86502450;
    // 0x865022F0: sw          $t3, 0x24($t9)
    MEM_W(0X24, ctx->r25) = ctx->r11;
L_865022F4:
    // 0x865022F4: bnel        $v0, $at, L_86502454
    if (ctx->r2 != ctx->r1) {
        // 0x865022F8: lhu         $t7, 0x0($s7)
        ctx->r15 = MEM_HU(ctx->r23, 0X0);
            goto L_86502454;
    }
    goto skip_2;
    // 0x865022F8: lhu         $t7, 0x0($s7)
    ctx->r15 = MEM_HU(ctx->r23, 0X0);
    skip_2:
    // 0x865022FC: lw          $v0, 0x17C($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X17C);
    // 0x86502300: lui         $at, 0x8651
    ctx->r1 = S32(RELOC_HI16(51, 0X92B0) << 16);
    // 0x86502304: lwc1        $f6, -0x6D50($at)
    ctx->f6.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(51, 0X92B0));
    // 0x86502308: lwc1        $f4, 0x28($v0)
    ctx->f4.u32l = MEM_W(ctx->r2, 0X28);
    // 0x8650230C: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x86502310: mul.s       $f8, $f4, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.fl); NAN_CHECK(ctx->f6.fl); 
    ctx->f8.fl = MUL_S(ctx->f4.fl, ctx->f6.fl);
    // 0x86502314: swc1        $f8, 0x28($v0)
    MEM_W(0X28, ctx->r2) = ctx->f8.u32l;
    // 0x86502318: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x8650231C: lw          $t4, 0x17C($v1)
    ctx->r12 = MEM_W(ctx->r3, 0X17C);
    // 0x86502320: lw          $t6, 0xF0($v1)
    ctx->r14 = MEM_W(ctx->r3, 0XF0);
    // 0x86502324: sw          $t6, 0x1C($t4)
    MEM_W(0X1C, ctx->r12) = ctx->r14;
    // 0x86502328: lw          $t5, 0xF4($v1)
    ctx->r13 = MEM_W(ctx->r3, 0XF4);
    // 0x8650232C: sw          $t5, 0x20($t4)
    MEM_W(0X20, ctx->r12) = ctx->r13;
    // 0x86502330: lw          $t6, 0xF8($v1)
    ctx->r14 = MEM_W(ctx->r3, 0XF8);
    // 0x86502334: b           L_86502450
    // 0x86502338: sw          $t6, 0x24($t4)
    MEM_W(0X24, ctx->r12) = ctx->r14;
        goto L_86502450;
    // 0x86502338: sw          $t6, 0x24($t4)
    MEM_W(0X24, ctx->r12) = ctx->r14;
L_8650233C:
    // 0x8650233C: lw          $v0, 0x4($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X4);
    // 0x86502340: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x86502344: bne         $v0, $zero, L_865023CC
    if (ctx->r2 != 0) {
        // 0x86502348: nop
    
            goto L_865023CC;
    }
    // 0x86502348: nop

    // 0x8650234C: lhu         $t7, 0x0($s7)
    ctx->r15 = MEM_HU(ctx->r23, 0X0);
    // 0x86502350: bnel        $t7, $zero, L_865023B0
    if (ctx->r15 != 0) {
        // 0x86502354: lw          $t8, 0x17C($v1)
        ctx->r24 = MEM_W(ctx->r3, 0X17C);
            goto L_865023B0;
    }
    goto skip_3;
    // 0x86502354: lw          $t8, 0x17C($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X17C);
    skip_3:
    // 0x86502358: lw          $v0, 0x17C($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X17C);
    // 0x8650235C: lui         $at, 0x8651
    ctx->r1 = S32(RELOC_HI16(51, 0X92B4) << 16);
    // 0x86502360: lwc1        $f0, 0x28($v0)
    ctx->f0.u32l = MEM_W(ctx->r2, 0X28);
    // 0x86502364: c.lt.s      $f20, $f0
    CHECK_FR(ctx, 20);
    CHECK_FR(ctx, 0);
    c1cs = ctx->f20.fl < ctx->f0.fl;
    // 0x86502368: nop

    // 0x8650236C: bc1fl       L_86502394
    if (!c1cs) {
        // 0x86502370: c.lt.s      $f0, $f20
        CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
            goto L_86502394;
    }
    goto skip_4;
    // 0x86502370: c.lt.s      $f0, $f20
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
    skip_4:
    // 0x86502374: lwc1        $f16, -0x6D4C($at)
    ctx->f16.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(51, 0X92B4));
    // 0x86502378: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x8650237C: sub.s       $f10, $f0, $f16
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f0.fl); NAN_CHECK(ctx->f16.fl); 
    ctx->f10.fl = ctx->f0.fl - ctx->f16.fl;
    // 0x86502380: swc1        $f10, 0x28($v0)
    MEM_W(0X28, ctx->r2) = ctx->f10.u32l;
    // 0x86502384: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x86502388: lw          $v0, 0x17C($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X17C);
    // 0x8650238C: lwc1        $f0, 0x28($v0)
    ctx->f0.u32l = MEM_W(ctx->r2, 0X28);
    // 0x86502390: c.lt.s      $f0, $f20
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
L_86502394:
    // 0x86502394: nop

    // 0x86502398: bc1fl       L_865023B0
    if (!c1cs) {
        // 0x8650239C: lw          $t8, 0x17C($v1)
        ctx->r24 = MEM_W(ctx->r3, 0X17C);
            goto L_865023B0;
    }
    goto skip_5;
    // 0x8650239C: lw          $t8, 0x17C($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X17C);
    skip_5:
    // 0x865023A0: swc1        $f20, 0x28($v0)
    MEM_W(0X28, ctx->r2) = ctx->f20.u32l;
    // 0x865023A4: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x865023A8: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x865023AC: lw          $t8, 0x17C($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X17C);
L_865023B0:
    // 0x865023B0: lw          $t2, 0x100($v1)
    ctx->r10 = MEM_W(ctx->r3, 0X100);
    // 0x865023B4: sw          $t2, 0x1C($t8)
    MEM_W(0X1C, ctx->r24) = ctx->r10;
    // 0x865023B8: lw          $t9, 0x104($v1)
    ctx->r25 = MEM_W(ctx->r3, 0X104);
    // 0x865023BC: sw          $t9, 0x20($t8)
    MEM_W(0X20, ctx->r24) = ctx->r25;
    // 0x865023C0: lw          $t2, 0x108($v1)
    ctx->r10 = MEM_W(ctx->r3, 0X108);
    // 0x865023C4: b           L_86502450
    // 0x865023C8: sw          $t2, 0x24($t8)
    MEM_W(0X24, ctx->r24) = ctx->r10;
        goto L_86502450;
    // 0x865023C8: sw          $t2, 0x24($t8)
    MEM_W(0X24, ctx->r24) = ctx->r10;
L_865023CC:
    // 0x865023CC: bnel        $v0, $at, L_86502454
    if (ctx->r2 != ctx->r1) {
        // 0x865023D0: lhu         $t7, 0x0($s7)
        ctx->r15 = MEM_HU(ctx->r23, 0X0);
            goto L_86502454;
    }
    goto skip_6;
    // 0x865023D0: lhu         $t7, 0x0($s7)
    ctx->r15 = MEM_HU(ctx->r23, 0X0);
    skip_6:
    // 0x865023D4: lhu         $t3, 0x0($s7)
    ctx->r11 = MEM_HU(ctx->r23, 0X0);
    // 0x865023D8: bnel        $t3, $zero, L_86502438
    if (ctx->r11 != 0) {
        // 0x865023DC: lw          $t4, 0x17C($v1)
        ctx->r12 = MEM_W(ctx->r3, 0X17C);
            goto L_86502438;
    }
    goto skip_7;
    // 0x865023DC: lw          $t4, 0x17C($v1)
    ctx->r12 = MEM_W(ctx->r3, 0X17C);
    skip_7:
    // 0x865023E0: lw          $v0, 0x17C($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X17C);
    // 0x865023E4: lui         $at, 0x8651
    ctx->r1 = S32(RELOC_HI16(51, 0X92B8) << 16);
    // 0x865023E8: lwc1        $f0, 0x28($v0)
    ctx->f0.u32l = MEM_W(ctx->r2, 0X28);
    // 0x865023EC: c.lt.s      $f20, $f0
    CHECK_FR(ctx, 20);
    CHECK_FR(ctx, 0);
    c1cs = ctx->f20.fl < ctx->f0.fl;
    // 0x865023F0: nop

    // 0x865023F4: bc1fl       L_8650241C
    if (!c1cs) {
        // 0x865023F8: c.lt.s      $f0, $f20
        CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
            goto L_8650241C;
    }
    goto skip_8;
    // 0x865023F8: c.lt.s      $f0, $f20
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
    skip_8:
    // 0x865023FC: lwc1        $f18, -0x6D48($at)
    ctx->f18.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(51, 0X92B8));
    // 0x86502400: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x86502404: sub.s       $f4, $f0, $f18
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f0.fl); NAN_CHECK(ctx->f18.fl); 
    ctx->f4.fl = ctx->f0.fl - ctx->f18.fl;
    // 0x86502408: swc1        $f4, 0x28($v0)
    MEM_W(0X28, ctx->r2) = ctx->f4.u32l;
    // 0x8650240C: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x86502410: lw          $v0, 0x17C($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X17C);
    // 0x86502414: lwc1        $f0, 0x28($v0)
    ctx->f0.u32l = MEM_W(ctx->r2, 0X28);
    // 0x86502418: c.lt.s      $f0, $f20
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 20);
    c1cs = ctx->f0.fl < ctx->f20.fl;
L_8650241C:
    // 0x8650241C: nop

    // 0x86502420: bc1fl       L_86502438
    if (!c1cs) {
        // 0x86502424: lw          $t4, 0x17C($v1)
        ctx->r12 = MEM_W(ctx->r3, 0X17C);
            goto L_86502438;
    }
    goto skip_9;
    // 0x86502424: lw          $t4, 0x17C($v1)
    ctx->r12 = MEM_W(ctx->r3, 0X17C);
    skip_9:
    // 0x86502428: swc1        $f20, 0x28($v0)
    MEM_W(0X28, ctx->r2) = ctx->f20.u32l;
    // 0x8650242C: lui         $v1, 0x8651
    ctx->r3 = S32(RELOC_HI16(51, 0XAB28) << 16);
    // 0x86502430: lw          $v1, -0x54D8($v1)
    ctx->r3 = MEM_W(ctx->r3, (int16_t)RELOC_LO16(51, 0XAB28));
    // 0x86502434: lw          $t4, 0x17C($v1)
    ctx->r12 = MEM_W(ctx->r3, 0X17C);
L_86502438:
    // 0x86502438: lw          $t6, 0xF0($v1)
    ctx->r14 = MEM_W(ctx->r3, 0XF0);
    // 0x8650243C: sw          $t6, 0x1C($t4)
    MEM_W(0X1C, ctx->r12) = ctx->r14;
    // 0x86502440: lw          $t5, 0xF4($v1)
    ctx->r13 = MEM_W(ctx->r3, 0XF4);
    // 0x86502444: sw          $t5, 0x20($t4)
    MEM_W(0X20, ctx->r12) = ctx->r13;
    // 0x86502448: lw          $t6, 0xF8($v1)
    ctx->r14 = MEM_W(ctx->r3, 0XF8);
    // 0x8650244C: sw          $t6, 0x24($t4)
    MEM_W(0X24, ctx->r12) = ctx->r14;
L_86502450:
    // 0x86502450: lhu         $t7, 0x0($s7)
    ctx->r15 = MEM_HU(ctx->r23, 0X0);
L_86502454:
    // 0x86502454: bnel        $t7, $zero, L_86502508
    if (ctx->r15 != 0) {
        // 0x86502458: or          $s2, $zero, $zero
        ctx->r18 = 0 | 0;
            goto L_86502508;
    }
    goto skip_10;
    // 0x86502458: or          $s2, $zero, $zero
    ctx->r18 = 0 | 0;
    skip_10:
    // 0x8650245C: jal         0x87B00050
    // 0x86502460: addiu       $a0, $zero, 0x2
    ctx->r4 = ADD32(0, 0X2);
    func_87B00050(rdram, ctx);
        goto after_2;
    // 0x86502460: addiu       $a0, $zero, 0x2
    ctx->r4 = ADD32(0, 0X2);
    after_2:
    // 0x86502464: bne         $v0, $zero, L_86502504
    if (ctx->r2 != 0) {
        // 0x86502468: or          $s2, $zero, $zero
        ctx->r18 = 0 | 0;
            goto L_86502504;
    }
    // 0x86502468: or          $s2, $zero, $zero
    ctx->r18 = 0 | 0;
    // 0x8650246C: lw          $v1, 0x0($s3)
    ctx->r3 = MEM_W(ctx->r19, 0X0);
L_86502470:
    // 0x86502470: multu       $s2, $s6
    result = U64(U32(ctx->r18)) * U64(U32(ctx->r22)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x86502474: addiu       $s2, $s2, 0x1
    ctx->r18 = ADD32(ctx->r18, 0X1);
    // 0x86502478: andi        $s2, $s2, 0xFF
    ctx->r18 = ctx->r18 & 0XFF;
    // 0x8650247C: slti        $at, $s2, 0xC
    ctx->r1 = SIGNED(ctx->r18) < 0XC ? 1 : 0;
    // 0x86502480: mflo        $s0
    ctx->r16 = lo;
    // 0x86502484: addu        $v0, $v1, $s0
    ctx->r2 = ADD32(ctx->r3, ctx->r16);
    // 0x86502488: lb          $t8, 0x0($v0)
    ctx->r24 = MEM_B(ctx->r2, 0X0);
    // 0x8650248C: bne         $s5, $t8, L_865024FC
    if (ctx->r21 != ctx->r24) {
        // 0x86502490: nop
    
            goto L_865024FC;
    }
    // 0x86502490: nop

    // 0x86502494: sb          $zero, 0x0($v0)
    MEM_B(0X0, ctx->r2) = 0;
    // 0x86502498: jal         0x87B00050
    // 0x8650249C: addiu       $a0, $zero, 0x50
    ctx->r4 = ADD32(0, 0X50);
    func_87B00050(rdram, ctx);
        goto after_3;
    // 0x8650249C: addiu       $a0, $zero, 0x50
    ctx->r4 = ADD32(0, 0X50);
    after_3:
    // 0x865024A0: mtc1        $v0, $f6
    ctx->f6.u32l = ctx->r2;
    // 0x865024A4: lui         $at, 0x4F80
    ctx->r1 = S32(0X4F80 << 16);
    // 0x865024A8: bgez        $v0, L_865024BC
    if (SIGNED(ctx->r2) >= 0) {
        // 0x865024AC: cvt.s.w     $f8, $f6
        CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.fl = CVT_S_W(ctx->f6.u32l);
            goto L_865024BC;
    }
    // 0x865024AC: cvt.s.w     $f8, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.fl = CVT_S_W(ctx->f6.u32l);
    // 0x865024B0: mtc1        $at, $f16
    ctx->f16.u32l = ctx->r1;
    // 0x865024B4: nop

    // 0x865024B8: add.s       $f8, $f8, $f16
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f8.fl); NAN_CHECK(ctx->f16.fl); 
    ctx->f8.fl = ctx->f8.fl + ctx->f16.fl;
L_865024BC:
    // 0x865024BC: lw          $t9, 0x0($s3)
    ctx->r25 = MEM_W(ctx->r19, 0X0);
    // 0x865024C0: addiu       $a0, $zero, 0x168
    ctx->r4 = ADD32(0, 0X168);
    // 0x865024C4: addu        $t2, $t9, $s0
    ctx->r10 = ADD32(ctx->r25, ctx->r16);
    // 0x865024C8: jal         0x87B00050
    // 0x865024CC: swc1        $f8, 0x4($t2)
    MEM_W(0X4, ctx->r10) = ctx->f8.u32l;
    func_87B00050(rdram, ctx);
        goto after_4;
    // 0x865024CC: swc1        $f8, 0x4($t2)
    MEM_W(0X4, ctx->r10) = ctx->f8.u32l;
    after_4:
    // 0x865024D0: mtc1        $v0, $f10
    ctx->f10.u32l = ctx->r2;
    // 0x865024D4: lui         $at, 0x4F80
    ctx->r1 = S32(0X4F80 << 16);
    // 0x865024D8: bgez        $v0, L_865024EC
    if (SIGNED(ctx->r2) >= 0) {
        // 0x865024DC: cvt.s.w     $f18, $f10
        CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 10);
    ctx->f18.fl = CVT_S_W(ctx->f10.u32l);
            goto L_865024EC;
    }
    // 0x865024DC: cvt.s.w     $f18, $f10
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 10);
    ctx->f18.fl = CVT_S_W(ctx->f10.u32l);
    // 0x865024E0: mtc1        $at, $f4
    ctx->f4.u32l = ctx->r1;
    // 0x865024E4: nop

    // 0x865024E8: add.s       $f18, $f18, $f4
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f18.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f18.fl = ctx->f18.fl + ctx->f4.fl;
L_865024EC:
    // 0x865024EC: lw          $t3, 0x0($s3)
    ctx->r11 = MEM_W(ctx->r19, 0X0);
    // 0x865024F0: addu        $t4, $t3, $s0
    ctx->r12 = ADD32(ctx->r11, ctx->r16);
    // 0x865024F4: b           L_86502504
    // 0x865024F8: swc1        $f18, 0x8($t4)
    MEM_W(0X8, ctx->r12) = ctx->f18.u32l;
        goto L_86502504;
    // 0x865024F8: swc1        $f18, 0x8($t4)
    MEM_W(0X8, ctx->r12) = ctx->f18.u32l;
L_865024FC:
    // 0x865024FC: bne         $at, $zero, L_86502470
    if (ctx->r1 != 0) {
        // 0x86502500: nop
    
            goto L_86502470;
    }
    // 0x86502500: nop

L_86502504:
    // 0x86502504: or          $s2, $zero, $zero
    ctx->r18 = 0 | 0;
L_86502508:
    // 0x86502508: multu       $s2, $s6
    result = U64(U32(ctx->r18)) * U64(U32(ctx->r22)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x8650250C: lw          $t5, 0x0($s3)
    ctx->r13 = MEM_W(ctx->r19, 0X0);
    // 0x86502510: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x86502514: mflo        $s0
    ctx->r16 = lo;
    // 0x86502518: addu        $t6, $t5, $s0
    ctx->r14 = ADD32(ctx->r13, ctx->r16);
    // 0x8650251C: lb          $t7, 0x0($t6)
    ctx->r15 = MEM_B(ctx->r14, 0X0);
    // 0x86502520: lui         $t5, 0x8650
    ctx->r13 = S32(RELOC_HI16(51, 0X2F50) << 16);
    // 0x86502524: addiu       $t5, $t5, 0x2F50
    ctx->r13 = ADD32(ctx->r13, (int16_t)RELOC_LO16(51, 0X2F50));
    // 0x86502528: beql        $s5, $t7, L_865026CC
    if (ctx->r21 == ctx->r15) {
        // 0x8650252C: addiu       $s2, $s2, 0x1
        ctx->r18 = ADD32(ctx->r18, 0X1);
            goto L_865026CC;
    }
    goto skip_11;
    // 0x8650252C: addiu       $s2, $s2, 0x1
    ctx->r18 = ADD32(ctx->r18, 0X1);
    skip_11:
    // 0x86502530: sw          $fp, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r30;
    // 0x86502534: lw          $t8, 0x0($s3)
    ctx->r24 = MEM_W(ctx->r19, 0X0);
    // 0x86502538: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650253C: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x86502540: addu        $t9, $t8, $s0
    ctx->r25 = ADD32(ctx->r24, ctx->r16);
    // 0x86502544: lb          $t2, 0x0($t9)
    ctx->r10 = MEM_B(ctx->r25, 0X0);
    // 0x86502548: lui         $t8, 0x700
    ctx->r24 = S32(0X700 << 16);
    // 0x8650254C: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502550: sll         $t3, $t2, 2
    ctx->r11 = S32(ctx->r10 << 2);
    // 0x86502554: subu        $t3, $t3, $t2
    ctx->r11 = SUB32(ctx->r11, ctx->r10);
    // 0x86502558: sll         $t3, $t3, 10
    ctx->r11 = S32(ctx->r11 << 10);
    // 0x8650255C: bgez        $t3, L_8650256C
    if (SIGNED(ctx->r11) >= 0) {
        // 0x86502560: sra         $t4, $t3, 1
        ctx->r12 = S32(SIGNED(ctx->r11) >> 1);
            goto L_8650256C;
    }
    // 0x86502560: sra         $t4, $t3, 1
    ctx->r12 = S32(SIGNED(ctx->r11) >> 1);
    // 0x86502564: addiu       $at, $t3, 0x1
    ctx->r1 = ADD32(ctx->r11, 0X1);
    // 0x86502568: sra         $t4, $at, 1
    ctx->r12 = S32(SIGNED(ctx->r1) >> 1);
L_8650256C:
    // 0x8650256C: addu        $t6, $t4, $t5
    ctx->r14 = ADD32(ctx->r12, ctx->r13);
    // 0x86502570: sw          $t6, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r14;
    // 0x86502574: lui         $t7, 0xF590
    ctx->r15 = S32(0XF590 << 16);
    // 0x86502578: sw          $t7, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r15;
    // 0x8650257C: sw          $t8, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r24;
    // 0x86502580: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x86502584: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502588: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x8650258C: lui         $t9, 0xE600
    ctx->r25 = S32(0XE600 << 16);
    // 0x86502590: sw          $t9, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r25;
    // 0x86502594: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502598: sw          $zero, 0x4($a0)
    MEM_W(0X4, ctx->r4) = 0;
    // 0x8650259C: lui         $t3, 0x72F
    ctx->r11 = S32(0X72F << 16);
    // 0x865025A0: ori         $t3, $t3, 0xF400
    ctx->r11 = ctx->r11 | 0XF400;
    // 0x865025A4: or          $t1, $s1, $zero
    ctx->r9 = ctx->r17 | 0;
    // 0x865025A8: lui         $t2, 0xF300
    ctx->r10 = S32(0XF300 << 16);
    // 0x865025AC: sw          $t2, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r10;
    // 0x865025B0: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x865025B4: sw          $t3, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r11;
    // 0x865025B8: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x865025BC: lui         $t4, 0xE700
    ctx->r12 = S32(0XE700 << 16);
    // 0x865025C0: sw          $t4, 0x0($t1)
    MEM_W(0X0, ctx->r9) = ctx->r12;
    // 0x865025C4: sw          $zero, 0x4($t1)
    MEM_W(0X4, ctx->r9) = 0;
    // 0x865025C8: lui         $t5, 0xF580
    ctx->r13 = S32(0XF580 << 16);
    // 0x865025CC: ori         $t5, $t5, 0x400
    ctx->r13 = ctx->r13 | 0X400;
    // 0x865025D0: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x865025D4: or          $t0, $s1, $zero
    ctx->r8 = ctx->r17 | 0;
    // 0x865025D8: sw          $t5, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r13;
    // 0x865025DC: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x865025E0: lui         $t7, 0x7
    ctx->r15 = S32(0X7 << 16);
    // 0x865025E4: ori         $t7, $t7, 0xC17C
    ctx->r15 = ctx->r15 | 0XC17C;
    // 0x865025E8: lui         $t6, 0xF200
    ctx->r14 = S32(0XF200 << 16);
    // 0x865025EC: sw          $t6, 0x0($t0)
    MEM_W(0X0, ctx->r8) = ctx->r14;
    // 0x865025F0: sw          $t7, 0x4($t0)
    MEM_W(0X4, ctx->r8) = ctx->r15;
    // 0x865025F4: lw          $t8, 0x0($s3)
    ctx->r24 = MEM_W(ctx->r19, 0X0);
    // 0x865025F8: mfc1        $a2, $f20
    ctx->r6 = (int32_t)ctx->f20.u32l;
    // 0x865025FC: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502600: addu        $v0, $t8, $s0
    ctx->r2 = ADD32(ctx->r24, ctx->r16);
    // 0x86502604: lw          $a1, 0x4($v0)
    ctx->r5 = MEM_W(ctx->r2, 0X4);
    // 0x86502608: lw          $a3, 0x8($v0)
    ctx->r7 = MEM_W(ctx->r2, 0X8);
    // 0x8650260C: jal         0x8005EDEC
    // 0x86502610: or          $a0, $s4, $zero
    ctx->r4 = ctx->r20 | 0;
    guRotateRPY(rdram, ctx);
        goto after_5;
    // 0x86502610: or          $a0, $s4, $zero
    ctx->r4 = ctx->r20 | 0;
    after_5:
    // 0x86502614: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x86502618: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650261C: lui         $t9, 0xDA38
    ctx->r25 = S32(0XDA38 << 16);
    // 0x86502620: lui         $t2, 0x100
    ctx->r10 = S32(0X100 << 16);
    // 0x86502624: sw          $t9, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r25;
    // 0x86502628: sw          $s4, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r20;
    // 0x8650262C: ori         $t2, $t2, 0x4008
    ctx->r10 = ctx->r10 | 0X4008;
    // 0x86502630: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x86502634: sw          $t2, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r10;
    // 0x86502638: lw          $t3, 0x0($s3)
    ctx->r11 = MEM_W(ctx->r19, 0X0);
    // 0x8650263C: lui         $t7, 0x8651
    ctx->r15 = S32(RELOC_HI16(51, 0X8F90) << 16);
    // 0x86502640: addiu       $t7, $t7, -0x7070
    ctx->r15 = ADD32(ctx->r15, (int16_t)RELOC_LO16(51, 0X8F90));
    // 0x86502644: addu        $t4, $t3, $s0
    ctx->r12 = ADD32(ctx->r11, ctx->r16);
    // 0x86502648: lb          $t5, 0x0($t4)
    ctx->r13 = MEM_B(ctx->r12, 0X0);
    // 0x8650264C: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502650: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x86502654: sll         $t6, $t5, 6
    ctx->r14 = S32(ctx->r13 << 6);
    // 0x86502658: addu        $t8, $t6, $t7
    ctx->r24 = ADD32(ctx->r14, ctx->r15);
    // 0x8650265C: sw          $t8, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r24;
    // 0x86502660: lui         $t9, 0x600
    ctx->r25 = S32(0X600 << 16);
    // 0x86502664: ori         $t9, $t9, 0x602
    ctx->r25 = ctx->r25 | 0X602;
    // 0x86502668: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650266C: addiu       $t2, $zero, 0x406
    ctx->r10 = ADD32(0, 0X406);
    // 0x86502670: sw          $t2, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r10;
    // 0x86502674: sw          $t9, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r25;
    // 0x86502678: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x8650267C: lui         $t3, 0xD838
    ctx->r11 = S32(0XD838 << 16);
    // 0x86502680: ori         $t3, $t3, 0x2
    ctx->r11 = ctx->r11 | 0X2;
    // 0x86502684: addiu       $t4, $zero, 0x40
    ctx->r12 = ADD32(0, 0X40);
    // 0x86502688: sw          $t4, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r12;
    // 0x8650268C: sw          $t3, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r11;
    // 0x86502690: lhu         $t5, 0x0($s7)
    ctx->r13 = MEM_HU(ctx->r23, 0X0);
    // 0x86502694: addiu       $s4, $s4, 0x40
    ctx->r20 = ADD32(ctx->r20, 0X40);
    // 0x86502698: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650269C: bnel        $t5, $zero, L_865026CC
    if (ctx->r13 != 0) {
        // 0x865026A0: addiu       $s2, $s2, 0x1
        ctx->r18 = ADD32(ctx->r18, 0X1);
            goto L_865026CC;
    }
    goto skip_12;
    // 0x865026A0: addiu       $s2, $s2, 0x1
    ctx->r18 = ADD32(ctx->r18, 0X1);
    skip_12:
    // 0x865026A4: lw          $t6, 0x0($s3)
    ctx->r14 = MEM_W(ctx->r19, 0X0);
    // 0x865026A8: addiu       $at, $zero, 0x7
    ctx->r1 = ADD32(0, 0X7);
    // 0x865026AC: addu        $v0, $t6, $s0
    ctx->r2 = ADD32(ctx->r14, ctx->r16);
    // 0x865026B0: lb          $v1, 0x0($v0)
    ctx->r3 = MEM_B(ctx->r2, 0X0);
    // 0x865026B4: bne         $v1, $at, L_865026C4
    if (ctx->r3 != ctx->r1) {
        // 0x865026B8: addiu       $t7, $v1, 0x1
        ctx->r15 = ADD32(ctx->r3, 0X1);
            goto L_865026C4;
    }
    // 0x865026B8: addiu       $t7, $v1, 0x1
    ctx->r15 = ADD32(ctx->r3, 0X1);
    // 0x865026BC: b           L_865026C8
    // 0x865026C0: sb          $s5, 0x0($v0)
    MEM_B(0X0, ctx->r2) = ctx->r21;
        goto L_865026C8;
    // 0x865026C0: sb          $s5, 0x0($v0)
    MEM_B(0X0, ctx->r2) = ctx->r21;
L_865026C4:
    // 0x865026C4: sb          $t7, 0x0($v0)
    MEM_B(0X0, ctx->r2) = ctx->r15;
L_865026C8:
    // 0x865026C8: addiu       $s2, $s2, 0x1
    ctx->r18 = ADD32(ctx->r18, 0X1);
L_865026CC:
    // 0x865026CC: andi        $s2, $s2, 0xFF
    ctx->r18 = ctx->r18 & 0XFF;
    // 0x865026D0: slti        $at, $s2, 0xC
    ctx->r1 = SIGNED(ctx->r18) < 0XC ? 1 : 0;
    // 0x865026D4: bne         $at, $zero, L_86502508
    if (ctx->r1 != 0) {
        // 0x865026D8: nop
    
            goto L_86502508;
    }
    // 0x865026D8: nop

    // 0x865026DC: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x865026E0: sw          $fp, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r30;
    // 0x865026E4: lui         $t8, 0x87B0
    ctx->r24 = S32(RELOC_HI16(26, 0XC0) << 16);
    // 0x865026E8: lhu         $t8, 0xC0($t8)
    ctx->r24 = MEM_HU(ctx->r24, (int16_t)RELOC_LO16(26, 0XC0));
    // 0x865026EC: lui         $t4, 0x8650
    ctx->r12 = S32(RELOC_HI16(51, 0X5F50) << 16);
    // 0x865026F0: addiu       $t4, $t4, 0x5F50
    ctx->r12 = ADD32(ctx->r12, (int16_t)RELOC_LO16(51, 0X5F50));
    // 0x865026F4: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x865026F8: bgez        $t8, L_8650270C
    if (SIGNED(ctx->r24) >= 0) {
        // 0x865026FC: andi        $t9, $t8, 0x3
        ctx->r25 = ctx->r24 & 0X3;
            goto L_8650270C;
    }
    // 0x865026FC: andi        $t9, $t8, 0x3
    ctx->r25 = ctx->r24 & 0X3;
    // 0x86502700: beq         $t9, $zero, L_8650270C
    if (ctx->r25 == 0) {
        // 0x86502704: nop
    
            goto L_8650270C;
    }
    // 0x86502704: nop

    // 0x86502708: addiu       $t9, $t9, -0x4
    ctx->r25 = ADD32(ctx->r25, -0X4);
L_8650270C:
    // 0x8650270C: sll         $t2, $t9, 10
    ctx->r10 = S32(ctx->r25 << 10);
    // 0x86502710: bgez        $t2, L_86502720
    if (SIGNED(ctx->r10) >= 0) {
        // 0x86502714: sra         $t3, $t2, 1
        ctx->r11 = S32(SIGNED(ctx->r10) >> 1);
            goto L_86502720;
    }
    // 0x86502714: sra         $t3, $t2, 1
    ctx->r11 = S32(SIGNED(ctx->r10) >> 1);
    // 0x86502718: addiu       $at, $t2, 0x1
    ctx->r1 = ADD32(ctx->r10, 0X1);
    // 0x8650271C: sra         $t3, $at, 1
    ctx->r11 = S32(SIGNED(ctx->r1) >> 1);
L_86502720:
    // 0x86502720: addu        $t5, $t3, $t4
    ctx->r13 = ADD32(ctx->r11, ctx->r12);
    // 0x86502724: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x86502728: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650272C: sw          $t5, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r13;
    // 0x86502730: lui         $t6, 0xF590
    ctx->r14 = S32(0XF590 << 16);
    // 0x86502734: sw          $t6, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r14;
    // 0x86502738: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x8650273C: lui         $t7, 0x700
    ctx->r15 = S32(0X700 << 16);
    // 0x86502740: sw          $t7, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r15;
    // 0x86502744: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502748: lui         $t8, 0xE600
    ctx->r24 = S32(0XE600 << 16);
    // 0x8650274C: sw          $t8, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r24;
    // 0x86502750: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x86502754: sw          $zero, 0x4($a0)
    MEM_W(0X4, ctx->r4) = 0;
    // 0x86502758: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x8650275C: lui         $t2, 0x70F
    ctx->r10 = S32(0X70F << 16);
    // 0x86502760: ori         $t2, $t2, 0xF400
    ctx->r10 = ctx->r10 | 0XF400;
    // 0x86502764: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x86502768: lui         $t9, 0xF300
    ctx->r25 = S32(0XF300 << 16);
    // 0x8650276C: sw          $t9, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r25;
    // 0x86502770: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502774: sw          $t2, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r10;
    // 0x86502778: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x8650277C: lui         $t3, 0xE700
    ctx->r11 = S32(0XE700 << 16);
    // 0x86502780: sw          $t3, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r11;
    // 0x86502784: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x86502788: sw          $zero, 0x4($a2)
    MEM_W(0X4, ctx->r6) = 0;
    // 0x8650278C: lui         $t4, 0xF580
    ctx->r12 = S32(0XF580 << 16);
    // 0x86502790: ori         $t4, $t4, 0x400
    ctx->r12 = ctx->r12 | 0X400;
    // 0x86502794: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x86502798: sw          $t4, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r12;
    // 0x8650279C: sw          $zero, 0x4($v0)
    MEM_W(0X4, ctx->r2) = 0;
    // 0x865027A0: lui         $t6, 0x7
    ctx->r14 = S32(0X7 << 16);
    // 0x865027A4: ori         $t6, $t6, 0xC07C
    ctx->r14 = ctx->r14 | 0XC07C;
    // 0x865027A8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x865027AC: lui         $t5, 0xF200
    ctx->r13 = S32(0XF200 << 16);
    // 0x865027B0: lui         $t7, 0x100
    ctx->r15 = S32(0X100 << 16);
    // 0x865027B4: sw          $t5, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r13;
    // 0x865027B8: sw          $t6, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r14;
    // 0x865027BC: ori         $t7, $t7, 0x4008
    ctx->r15 = ctx->r15 | 0X4008;
    // 0x865027C0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x865027C4: sw          $t7, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r15;
    // 0x865027C8: lw          $t8, 0x4C($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X4C);
    // 0x865027CC: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x865027D0: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x865027D4: lui         $t9, 0x600
    ctx->r25 = S32(0X600 << 16);
    // 0x865027D8: sw          $t8, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r24;
    // 0x865027DC: ori         $t9, $t9, 0x602
    ctx->r25 = ctx->r25 | 0X602;
    // 0x865027E0: addiu       $t2, $zero, 0x406
    ctx->r10 = ADD32(0, 0X406);
    // 0x865027E4: sw          $t2, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r10;
    // 0x865027E8: sw          $t9, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r25;
    // 0x865027EC: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
L_865027F0:
    // 0x865027F0: lbu         $v1, 0xC7($sp)
    ctx->r3 = MEM_BU(ctx->r29, 0XC7);
L_865027F4:
    // 0x865027F4: lui         $t3, 0xDF00
    ctx->r11 = S32(0XDF00 << 16);
    // 0x865027F8: sw          $t3, 0x0($s1)
    MEM_W(0X0, ctx->r17) = ctx->r11;
    // 0x865027FC: addiu       $v1, $v1, 0x1
    ctx->r3 = ADD32(ctx->r3, 0X1);
    // 0x86502800: andi        $v1, $v1, 0xFF
    ctx->r3 = ctx->r3 & 0XFF;
    // 0x86502804: slti        $at, $v1, 0x4
    ctx->r1 = SIGNED(ctx->r3) < 0X4 ? 1 : 0;
    // 0x86502808: sw          $zero, 0x4($s1)
    MEM_W(0X4, ctx->r17) = 0;
    // 0x8650280C: bne         $at, $zero, L_86502180
    if (ctx->r1 != 0) {
        // 0x86502810: sb          $v1, 0xC7($sp)
        MEM_B(0XC7, ctx->r29) = ctx->r3;
            goto L_86502180;
    }
    // 0x86502810: sb          $v1, 0xC7($sp)
    MEM_B(0XC7, ctx->r29) = ctx->r3;
    // 0x86502814: lw          $ra, 0x44($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X44);
    // 0x86502818: ldc1        $f20, 0x18($sp)
    CHECK_FR(ctx, 20);
    ctx->f20.u64 = LD(ctx->r29, 0X18);
    // 0x8650281C: lw          $s0, 0x20($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X20);
    // 0x86502820: lw          $s1, 0x24($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X24);
    // 0x86502824: lw          $s2, 0x28($sp)
    ctx->r18 = MEM_W(ctx->r29, 0X28);
    // 0x86502828: lw          $s3, 0x2C($sp)
    ctx->r19 = MEM_W(ctx->r29, 0X2C);
    // 0x8650282C: lw          $s4, 0x30($sp)
    ctx->r20 = MEM_W(ctx->r29, 0X30);
    // 0x86502830: lw          $s5, 0x34($sp)
    ctx->r21 = MEM_W(ctx->r29, 0X34);
    // 0x86502834: lw          $s6, 0x38($sp)
    ctx->r22 = MEM_W(ctx->r29, 0X38);
    // 0x86502838: lw          $s7, 0x3C($sp)
    ctx->r23 = MEM_W(ctx->r29, 0X3C);
    // 0x8650283C: lw          $fp, 0x40($sp)
    ctx->r30 = MEM_W(ctx->r29, 0X40);
    // 0x86502840: jr          $ra
    // 0x86502844: addiu       $sp, $sp, 0xC8
    ctx->r29 = ADD32(ctx->r29, 0XC8);
    return;
    // 0x86502844: addiu       $sp, $sp, 0xC8
    ctx->r29 = ADD32(ctx->r29, 0XC8);
;}
RECOMP_FUNC void func_87A009F0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x87A009F0: addiu       $sp, $sp, -0xA0
    ctx->r29 = ADD32(ctx->r29, -0XA0);
    // 0x87A009F4: lui         $v0, 0x800A
    ctx->r2 = S32(0X800A << 16);
    // 0x87A009F8: lw          $v0, 0x7420($v0)
    ctx->r2 = MEM_W(ctx->r2, 0X7420);
    // 0x87A009FC: sw          $s2, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r18;
    // 0x87A00A00: sw          $ra, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r31;
    // 0x87A00A04: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x87A00A08: sw          $fp, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r30;
    // 0x87A00A0C: sw          $s7, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r23;
    // 0x87A00A10: sw          $s6, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r22;
    // 0x87A00A14: sw          $s5, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r21;
    // 0x87A00A18: sw          $s4, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r20;
    // 0x87A00A1C: sw          $s3, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r19;
    // 0x87A00A20: sw          $s1, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r17;
    // 0x87A00A24: sw          $s0, 0x8($sp)
    MEM_W(0X8, ctx->r29) = ctx->r16;
    // 0x87A00A28: lui         $s2, 0xE700
    ctx->r18 = S32(0XE700 << 16);
    // 0x87A00A2C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00A30: sw          $s2, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r18;
    // 0x87A00A34: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x87A00A38: or          $a1, $v0, $zero
    ctx->r5 = ctx->r2 | 0;
    // 0x87A00A3C: lui         $t6, 0xE300
    ctx->r14 = S32(0XE300 << 16);
    // 0x87A00A40: ori         $t6, $t6, 0xA01
    ctx->r14 = ctx->r14 | 0XA01;
    // 0x87A00A44: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00A48: sw          $t6, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r14;
    // 0x87A00A4C: or          $a2, $v0, $zero
    ctx->r6 = ctx->r2 | 0;
    // 0x87A00A50: lui         $t7, 0xD9FF
    ctx->r15 = S32(0XD9FF << 16);
    // 0x87A00A54: sw          $zero, 0x4($a1)
    MEM_W(0X4, ctx->r5) = 0;
    // 0x87A00A58: ori         $t7, $t7, 0xFFFE
    ctx->r15 = ctx->r15 | 0XFFFE;
    // 0x87A00A5C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00A60: sw          $t7, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r15;
    // 0x87A00A64: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    // 0x87A00A68: lui         $t8, 0xD9FF
    ctx->r24 = S32(0XD9FF << 16);
    // 0x87A00A6C: sw          $zero, 0x4($a2)
    MEM_W(0X4, ctx->r6) = 0;
    // 0x87A00A70: ori         $t8, $t8, 0xFFFF
    ctx->r24 = ctx->r24 | 0XFFFF;
    // 0x87A00A74: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00A78: sw          $t8, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r24;
    // 0x87A00A7C: or          $t0, $v0, $zero
    ctx->r8 = ctx->r2 | 0;
    // 0x87A00A80: sw          $zero, 0x4($a3)
    MEM_W(0X4, ctx->r7) = 0;
    // 0x87A00A84: lui         $t6, 0xFFFC
    ctx->r14 = S32(0XFFFC << 16);
    // 0x87A00A88: lui         $t9, 0xFCFF
    ctx->r25 = S32(0XFCFF << 16);
    // 0x87A00A8C: ori         $t9, $t9, 0xFFFF
    ctx->r25 = ctx->r25 | 0XFFFF;
    // 0x87A00A90: ori         $t6, $t6, 0xF279
    ctx->r14 = ctx->r14 | 0XF279;
    // 0x87A00A94: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00A98: sw          $t6, 0x4($t0)
    MEM_W(0X4, ctx->r8) = ctx->r14;
    // 0x87A00A9C: sw          $t9, 0x0($t0)
    MEM_W(0X0, ctx->r8) = ctx->r25;
    // 0x87A00AA0: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x87A00AA4: lui         $t7, 0xE300
    ctx->r15 = S32(0XE300 << 16);
    // 0x87A00AA8: ori         $t7, $t7, 0xF00
    ctx->r15 = ctx->r15 | 0XF00;
    // 0x87A00AAC: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00AB0: sw          $t7, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r15;
    // 0x87A00AB4: or          $a1, $v0, $zero
    ctx->r5 = ctx->r2 | 0;
    // 0x87A00AB8: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x87A00ABC: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00AC0: lui         $t8, 0xE300
    ctx->r24 = S32(0XE300 << 16);
    // 0x87A00AC4: ori         $t8, $t8, 0x1201
    ctx->r24 = ctx->r24 | 0X1201;
    // 0x87A00AC8: addiu       $t9, $zero, 0x2000
    ctx->r25 = ADD32(0, 0X2000);
    // 0x87A00ACC: or          $a2, $v0, $zero
    ctx->r6 = ctx->r2 | 0;
    // 0x87A00AD0: sw          $t9, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r25;
    // 0x87A00AD4: sw          $t8, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r24;
    // 0x87A00AD8: lui         $t6, 0xE300
    ctx->r14 = S32(0XE300 << 16);
    // 0x87A00ADC: ori         $t6, $t6, 0x1402
    ctx->r14 = ctx->r14 | 0X1402;
    // 0x87A00AE0: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00AE4: addiu       $t7, $zero, 0xC00
    ctx->r15 = ADD32(0, 0XC00);
    // 0x87A00AE8: sw          $t7, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r15;
    // 0x87A00AEC: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x87A00AF0: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    // 0x87A00AF4: lui         $t8, 0xE300
    ctx->r24 = S32(0XE300 << 16);
    // 0x87A00AF8: ori         $t8, $t8, 0x1001
    ctx->r24 = ctx->r24 | 0X1001;
    // 0x87A00AFC: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B00: sw          $t8, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r24;
    // 0x87A00B04: sw          $zero, 0x4($a3)
    MEM_W(0X4, ctx->r7) = 0;
    // 0x87A00B08: or          $t0, $v0, $zero
    ctx->r8 = ctx->r2 | 0;
    // 0x87A00B0C: lui         $t9, 0xE300
    ctx->r25 = S32(0XE300 << 16);
    // 0x87A00B10: ori         $t9, $t9, 0xC00
    ctx->r25 = ctx->r25 | 0XC00;
    // 0x87A00B14: sw          $t9, 0x0($t0)
    MEM_W(0X0, ctx->r8) = ctx->r25;
    // 0x87A00B18: sw          $zero, 0x4($t0)
    MEM_W(0X4, ctx->r8) = 0;
    // 0x87A00B1C: addiu       $t6, $zero, 0x6
    ctx->r14 = ADD32(0, 0X6);
    // 0x87A00B20: addiu       $t7, $a0, 0xF00
    ctx->r15 = ADD32(ctx->r4, 0XF00);
    // 0x87A00B24: lui         $s5, 0x708
    ctx->r21 = S32(0X708 << 16);
    // 0x87A00B28: lui         $fp, 0x777
    ctx->r30 = S32(0X777 << 16);
    // 0x87A00B2C: lui         $ra, 0xF510
    ctx->r31 = S32(0XF510 << 16);
    // 0x87A00B30: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B34: ori         $ra, $ra, 0xA000
    ctx->r31 = ctx->r31 | 0XA000;
    // 0x87A00B38: ori         $fp, $fp, 0xF01A
    ctx->r30 = ctx->r30 | 0XF01A;
    // 0x87A00B3C: ori         $s5, $s5, 0x200
    ctx->r21 = ctx->r21 | 0X200;
    // 0x87A00B40: sw          $t7, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r15;
    // 0x87A00B44: sw          $t6, 0x38($sp)
    MEM_W(0X38, ctx->r29) = ctx->r14;
    // 0x87A00B48: sw          $a0, 0x40($sp)
    MEM_W(0X40, ctx->r29) = ctx->r4;
    // 0x87A00B4C: sw          $zero, 0x3C($sp)
    MEM_W(0X3C, ctx->r29) = 0;
    // 0x87A00B50: addiu       $s1, $zero, 0xC
    ctx->r17 = ADD32(0, 0XC);
    // 0x87A00B54: lui         $s3, 0xFD10
    ctx->r19 = S32(0XFD10 << 16);
    // 0x87A00B58: lui         $s4, 0xF510
    ctx->r20 = S32(0XF510 << 16);
    // 0x87A00B5C: lui         $s6, 0xE600
    ctx->r22 = S32(0XE600 << 16);
    // 0x87A00B60: lui         $s7, 0xF300
    ctx->r23 = S32(0XF300 << 16);
L_87A00B64:
    // 0x87A00B64: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x87A00B68: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B6C: sw          $s2, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r18;
    // 0x87A00B70: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x87A00B74: or          $a0, $v0, $zero
    ctx->r4 = ctx->r2 | 0;
    // 0x87A00B78: sw          $s3, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r19;
    // 0x87A00B7C: lw          $t8, 0x40($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X40);
    // 0x87A00B80: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B84: or          $a1, $v0, $zero
    ctx->r5 = ctx->r2 | 0;
    // 0x87A00B88: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B8C: sw          $t8, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r24;
    // 0x87A00B90: or          $a2, $v0, $zero
    ctx->r6 = ctx->r2 | 0;
    // 0x87A00B94: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00B98: sw          $s5, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r21;
    // 0x87A00B9C: sw          $s4, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r20;
    // 0x87A00BA0: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    // 0x87A00BA4: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00BA8: sw          $zero, 0x4($a2)
    MEM_W(0X4, ctx->r6) = 0;
    // 0x87A00BAC: sw          $s6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r22;
    // 0x87A00BB0: or          $t0, $v0, $zero
    ctx->r8 = ctx->r2 | 0;
    // 0x87A00BB4: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00BB8: sw          $fp, 0x4($a3)
    MEM_W(0X4, ctx->r7) = ctx->r30;
    // 0x87A00BBC: sw          $s7, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r23;
    // 0x87A00BC0: or          $t1, $v0, $zero
    ctx->r9 = ctx->r2 | 0;
    // 0x87A00BC4: sw          $zero, 0x4($t0)
    MEM_W(0X4, ctx->r8) = 0;
    // 0x87A00BC8: sw          $s2, 0x0($t0)
    MEM_W(0X0, ctx->r8) = ctx->r18;
    // 0x87A00BCC: lui         $t9, 0x8
    ctx->r25 = S32(0X8 << 16);
    // 0x87A00BD0: ori         $t9, $t9, 0x200
    ctx->r25 = ctx->r25 | 0X200;
    // 0x87A00BD4: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00BD8: or          $t2, $v0, $zero
    ctx->r10 = ctx->r2 | 0;
    // 0x87A00BDC: sw          $t9, 0x4($t1)
    MEM_W(0X4, ctx->r9) = ctx->r25;
    // 0x87A00BE0: sw          $ra, 0x0($t1)
    MEM_W(0X0, ctx->r9) = ctx->r31;
    // 0x87A00BE4: lui         $t7, 0x4F
    ctx->r15 = S32(0X4F << 16);
    // 0x87A00BE8: ori         $t7, $t7, 0xC014
    ctx->r15 = ctx->r15 | 0XC014;
    // 0x87A00BEC: lui         $t6, 0xF200
    ctx->r14 = S32(0XF200 << 16);
    // 0x87A00BF0: sw          $t6, 0x0($t2)
    MEM_W(0X0, ctx->r10) = ctx->r14;
    // 0x87A00BF4: sw          $t7, 0x4($t2)
    MEM_W(0X4, ctx->r10) = ctx->r15;
    // 0x87A00BF8: lw          $s0, 0x38($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X38);
    // 0x87A00BFC: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C00: lui         $at, 0xE450
    ctx->r1 = S32(0XE450 << 16);
    // 0x87A00C04: sll         $s0, $s0, 2
    ctx->r16 = S32(ctx->r16 << 2);
    // 0x87A00C08: andi        $t8, $s0, 0xFFF
    ctx->r24 = ctx->r16 & 0XFFF;
    // 0x87A00C0C: or          $t9, $t8, $at
    ctx->r25 = ctx->r24 | ctx->r1;
    // 0x87A00C10: or          $t3, $v0, $zero
    ctx->r11 = ctx->r2 | 0;
    // 0x87A00C14: sw          $t9, 0x0($t3)
    MEM_W(0X0, ctx->r11) = ctx->r25;
    // 0x87A00C18: lw          $t6, 0x3C($sp)
    ctx->r14 = MEM_W(ctx->r29, 0X3C);
    // 0x87A00C1C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C20: or          $t4, $v0, $zero
    ctx->r12 = ctx->r2 | 0;
    // 0x87A00C24: sll         $t7, $t6, 2
    ctx->r15 = S32(ctx->r14 << 2);
    // 0x87A00C28: andi        $t8, $t7, 0xFFF
    ctx->r24 = ctx->r15 & 0XFFF;
    // 0x87A00C2C: sw          $t8, 0x4($t3)
    MEM_W(0X4, ctx->r11) = ctx->r24;
    // 0x87A00C30: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C34: or          $t5, $v0, $zero
    ctx->r13 = ctx->r2 | 0;
    // 0x87A00C38: lui         $t9, 0xE100
    ctx->r25 = S32(0XE100 << 16);
    // 0x87A00C3C: sw          $t9, 0x0($t4)
    MEM_W(0X0, ctx->r12) = ctx->r25;
    // 0x87A00C40: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C44: sw          $zero, 0x4($t4)
    MEM_W(0X4, ctx->r12) = 0;
    // 0x87A00C48: lui         $t7, 0x400
    ctx->r15 = S32(0X400 << 16);
    // 0x87A00C4C: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x87A00C50: ori         $t7, $t7, 0x400
    ctx->r15 = ctx->r15 | 0X400;
    // 0x87A00C54: lui         $t6, 0xF100
    ctx->r14 = S32(0XF100 << 16);
    // 0x87A00C58: sw          $t6, 0x0($t5)
    MEM_W(0X0, ctx->r13) = ctx->r14;
    // 0x87A00C5C: sw          $t7, 0x4($t5)
    MEM_W(0X4, ctx->r13) = ctx->r15;
    // 0x87A00C60: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C64: or          $a0, $v0, $zero
    ctx->r4 = ctx->r2 | 0;
    // 0x87A00C68: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x87A00C6C: sw          $s2, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r18;
    // 0x87A00C70: sw          $s3, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r19;
    // 0x87A00C74: lw          $t8, 0x34($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X34);
    // 0x87A00C78: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C7C: or          $a1, $v0, $zero
    ctx->r5 = ctx->r2 | 0;
    // 0x87A00C80: sw          $t8, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r24;
    // 0x87A00C84: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C88: or          $a2, $v0, $zero
    ctx->r6 = ctx->r2 | 0;
    // 0x87A00C8C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00C90: sw          $s5, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r21;
    // 0x87A00C94: sw          $s4, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r20;
    // 0x87A00C98: or          $a3, $v0, $zero
    ctx->r7 = ctx->r2 | 0;
    // 0x87A00C9C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00CA0: sw          $zero, 0x4($a2)
    MEM_W(0X4, ctx->r6) = 0;
    // 0x87A00CA4: sw          $s6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r22;
    // 0x87A00CA8: or          $t0, $v0, $zero
    ctx->r8 = ctx->r2 | 0;
    // 0x87A00CAC: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00CB0: sw          $fp, 0x4($a3)
    MEM_W(0X4, ctx->r7) = ctx->r30;
    // 0x87A00CB4: sw          $s7, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r23;
    // 0x87A00CB8: or          $t1, $v0, $zero
    ctx->r9 = ctx->r2 | 0;
    // 0x87A00CBC: lui         $t9, 0x8
    ctx->r25 = S32(0X8 << 16);
    // 0x87A00CC0: ori         $t9, $t9, 0x200
    ctx->r25 = ctx->r25 | 0X200;
    // 0x87A00CC4: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00CC8: sw          $zero, 0x4($t0)
    MEM_W(0X4, ctx->r8) = 0;
    // 0x87A00CCC: sw          $s2, 0x0($t0)
    MEM_W(0X0, ctx->r8) = ctx->r18;
    // 0x87A00CD0: sw          $t9, 0x4($t1)
    MEM_W(0X4, ctx->r9) = ctx->r25;
    // 0x87A00CD4: or          $t2, $v0, $zero
    ctx->r10 = ctx->r2 | 0;
    // 0x87A00CD8: sw          $ra, 0x0($t1)
    MEM_W(0X0, ctx->r9) = ctx->r31;
    // 0x87A00CDC: lui         $t7, 0x4F
    ctx->r15 = S32(0X4F << 16);
    // 0x87A00CE0: ori         $t7, $t7, 0xC014
    ctx->r15 = ctx->r15 | 0XC014;
    // 0x87A00CE4: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00CE8: sll         $t8, $s1, 2
    ctx->r24 = S32(ctx->r17 << 2);
    // 0x87A00CEC: lui         $t6, 0xF200
    ctx->r14 = S32(0XF200 << 16);
    // 0x87A00CF0: sw          $t6, 0x0($t2)
    MEM_W(0X0, ctx->r10) = ctx->r14;
    // 0x87A00CF4: andi        $t9, $t8, 0xFFF
    ctx->r25 = ctx->r24 & 0XFFF;
    // 0x87A00CF8: or          $t3, $v0, $zero
    ctx->r11 = ctx->r2 | 0;
    // 0x87A00CFC: sw          $t7, 0x4($t2)
    MEM_W(0X4, ctx->r10) = ctx->r15;
    // 0x87A00D00: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00D04: or          $t6, $t9, $at
    ctx->r14 = ctx->r25 | ctx->r1;
    // 0x87A00D08: sw          $t6, 0x0($t3)
    MEM_W(0X0, ctx->r11) = ctx->r14;
    // 0x87A00D0C: or          $t4, $v0, $zero
    ctx->r12 = ctx->r2 | 0;
    // 0x87A00D10: andi        $t7, $s0, 0xFFF
    ctx->r15 = ctx->r16 & 0XFFF;
    // 0x87A00D14: sw          $t7, 0x4($t3)
    MEM_W(0X4, ctx->r11) = ctx->r15;
    // 0x87A00D18: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00D1C: lui         $t8, 0xE100
    ctx->r24 = S32(0XE100 << 16);
    // 0x87A00D20: sw          $t8, 0x0($t4)
    MEM_W(0X0, ctx->r12) = ctx->r24;
    // 0x87A00D24: or          $t5, $v0, $zero
    ctx->r13 = ctx->r2 | 0;
    // 0x87A00D28: sw          $zero, 0x4($t4)
    MEM_W(0X4, ctx->r12) = 0;
    // 0x87A00D2C: lui         $t6, 0x400
    ctx->r14 = S32(0X400 << 16);
    // 0x87A00D30: ori         $t6, $t6, 0x400
    ctx->r14 = ctx->r14 | 0X400;
    // 0x87A00D34: lui         $t9, 0xF100
    ctx->r25 = S32(0XF100 << 16);
    // 0x87A00D38: sw          $t9, 0x0($t5)
    MEM_W(0X0, ctx->r13) = ctx->r25;
    // 0x87A00D3C: sw          $t6, 0x4($t5)
    MEM_W(0X4, ctx->r13) = ctx->r14;
    // 0x87A00D40: lw          $t9, 0x3C($sp)
    ctx->r25 = MEM_W(ctx->r29, 0X3C);
    // 0x87A00D44: lw          $t7, 0x40($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X40);
    // 0x87A00D48: addiu       $at, $zero, 0xFC
    ctx->r1 = ADD32(0, 0XFC);
    // 0x87A00D4C: addiu       $t6, $t9, 0xC
    ctx->r14 = ADD32(ctx->r25, 0XC);
    // 0x87A00D50: addiu       $t8, $t7, 0x1E00
    ctx->r24 = ADD32(ctx->r15, 0X1E00);
    // 0x87A00D54: lw          $t7, 0x38($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X38);
    // 0x87A00D58: lw          $t9, 0x34($sp)
    ctx->r25 = MEM_W(ctx->r29, 0X34);
    // 0x87A00D5C: sw          $t8, 0x40($sp)
    MEM_W(0X40, ctx->r29) = ctx->r24;
    // 0x87A00D60: sw          $t6, 0x3C($sp)
    MEM_W(0X3C, ctx->r29) = ctx->r14;
    // 0x87A00D64: addiu       $s1, $s1, 0xC
    ctx->r17 = ADD32(ctx->r17, 0XC);
    // 0x87A00D68: addiu       $t8, $t7, 0xC
    ctx->r24 = ADD32(ctx->r15, 0XC);
    // 0x87A00D6C: addiu       $t6, $t9, 0x1E00
    ctx->r14 = ADD32(ctx->r25, 0X1E00);
    // 0x87A00D70: sw          $t6, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r14;
    // 0x87A00D74: sw          $t8, 0x38($sp)
    MEM_W(0X38, ctx->r29) = ctx->r24;
    // 0x87A00D78: bne         $s1, $at, L_87A00B64
    if (ctx->r17 != ctx->r1) {
        // 0x87A00D7C: addiu       $v0, $v0, 0x8
        ctx->r2 = ADD32(ctx->r2, 0X8);
            goto L_87A00B64;
    }
    // 0x87A00D7C: addiu       $v0, $v0, 0x8
    ctx->r2 = ADD32(ctx->r2, 0X8);
    // 0x87A00D80: lw          $ra, 0x2C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X2C);
    // 0x87A00D84: lui         $at, 0x800A
    ctx->r1 = S32(0X800A << 16);
    // 0x87A00D88: lw          $s0, 0x8($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X8);
    // 0x87A00D8C: lw          $s1, 0xC($sp)
    ctx->r17 = MEM_W(ctx->r29, 0XC);
    // 0x87A00D90: lw          $s2, 0x10($sp)
    ctx->r18 = MEM_W(ctx->r29, 0X10);
    // 0x87A00D94: lw          $s3, 0x14($sp)
    ctx->r19 = MEM_W(ctx->r29, 0X14);
    // 0x87A00D98: lw          $s4, 0x18($sp)
    ctx->r20 = MEM_W(ctx->r29, 0X18);
    // 0x87A00D9C: lw          $s5, 0x1C($sp)
    ctx->r21 = MEM_W(ctx->r29, 0X1C);
    // 0x87A00DA0: lw          $s6, 0x20($sp)
    ctx->r22 = MEM_W(ctx->r29, 0X20);
    // 0x87A00DA4: lw          $s7, 0x24($sp)
    ctx->r23 = MEM_W(ctx->r29, 0X24);
    // 0x87A00DA8: lw          $fp, 0x28($sp)
    ctx->r30 = MEM_W(ctx->r29, 0X28);
    // 0x87A00DAC: sw          $v0, 0x7420($at)
    MEM_W(0X7420, ctx->r1) = ctx->r2;
    // 0x87A00DB0: jr          $ra
    // 0x87A00DB4: addiu       $sp, $sp, 0xA0
    ctx->r29 = ADD32(ctx->r29, 0XA0);
    return;
    // 0x87A00DB4: addiu       $sp, $sp, 0xA0
    ctx->r29 = ADD32(ctx->r29, 0XA0);
;}
RECOMP_FUNC void func_86B06AB4(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86B06AB4: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    // 0x86B06AB8: mtc1        $a2, $f12
    ctx->f12.u32l = ctx->r6;
    // 0x86B06ABC: sll         $a3, $a3, 16
    ctx->r7 = S32(ctx->r7 << 16);
    // 0x86B06AC0: sra         $a3, $a3, 16
    ctx->r7 = S32(SIGNED(ctx->r7) >> 16);
    // 0x86B06AC4: sw          $a1, 0x80($a0)
    MEM_W(0X80, ctx->r4) = ctx->r5;
    // 0x86B06AC8: sh          $a3, 0x9C($a0)
    MEM_H(0X9C, ctx->r4) = ctx->r7;
    // 0x86B06ACC: swc1        $f12, 0x98($a0)
    MEM_W(0X98, ctx->r4) = ctx->f12.u32l;
    // 0x86B06AD0: lh          $t6, 0x12($sp)
    ctx->r14 = MEM_H(ctx->r29, 0X12);
    // 0x86B06AD4: mtc1        $zero, $f4
    ctx->f4.u32l = 0;
    // 0x86B06AD8: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x86B06ADC: sh          $t6, 0x9E($a0)
    MEM_H(0X9E, ctx->r4) = ctx->r14;
    // 0x86B06AE0: lh          $t7, 0x16($sp)
    ctx->r15 = MEM_H(ctx->r29, 0X16);
    // 0x86B06AE4: lui         $v0, 0x86B1
    ctx->r2 = S32(RELOC_HI16(75, 0XDCE0) << 16);
    // 0x86B06AE8: addiu       $v0, $v0, -0x2320
    ctx->r2 = ADD32(ctx->r2, (int16_t)RELOC_LO16(75, 0XDCE0));
    // 0x86B06AEC: sw          $zero, 0x88($a0)
    MEM_W(0X88, ctx->r4) = 0;
    // 0x86B06AF0: sw          $zero, 0x8C($a0)
    MEM_W(0X8C, ctx->r4) = 0;
    // 0x86B06AF4: sw          $zero, 0x84($a0)
    MEM_W(0X84, ctx->r4) = 0;
    // 0x86B06AF8: swc1        $f4, 0xA4($a0)
    MEM_W(0XA4, ctx->r4) = ctx->f4.u32l;
    // 0x86B06AFC: swc1        $f6, 0xAC($a0)
    MEM_W(0XAC, ctx->r4) = ctx->f6.u32l;
    // 0x86B06B00: sh          $t7, 0xA0($a0)
    MEM_H(0XA0, ctx->r4) = ctx->r15;
    // 0x86B06B04: lhu         $t8, 0x0($v0)
    ctx->r24 = MEM_HU(ctx->r2, 0X0);
    // 0x86B06B08: sh          $t8, 0xB0($a0)
    MEM_H(0XB0, ctx->r4) = ctx->r24;
    // 0x86B06B0C: lhu         $t9, 0x2($v0)
    ctx->r25 = MEM_HU(ctx->r2, 0X2);
    // 0x86B06B10: sh          $t9, 0xB2($a0)
    MEM_H(0XB2, ctx->r4) = ctx->r25;
    // 0x86B06B14: lhu         $t0, 0x4($v0)
    ctx->r8 = MEM_HU(ctx->r2, 0X4);
    // 0x86B06B18: sh          $t0, 0xB4($a0)
    MEM_H(0XB4, ctx->r4) = ctx->r8;
    // 0x86B06B1C: lhu         $t1, 0x6($v0)
    ctx->r9 = MEM_HU(ctx->r2, 0X6);
    // 0x86B06B20: sh          $t1, 0xB6($a0)
    MEM_H(0XB6, ctx->r4) = ctx->r9;
    // 0x86B06B24: lhu         $t2, 0x8($v0)
    ctx->r10 = MEM_HU(ctx->r2, 0X8);
    // 0x86B06B28: sh          $t2, 0xB8($a0)
    MEM_H(0XB8, ctx->r4) = ctx->r10;
    // 0x86B06B2C: lhu         $t3, 0xA($v0)
    ctx->r11 = MEM_HU(ctx->r2, 0XA);
    // 0x86B06B30: jr          $ra
    // 0x86B06B34: sh          $t3, 0xBA($a0)
    MEM_H(0XBA, ctx->r4) = ctx->r11;
    return;
    // 0x86B06B34: sh          $t3, 0xBA($a0)
    MEM_H(0XBA, ctx->r4) = ctx->r11;
;}
RECOMP_FUNC void func_86B042B4(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86B042B4: lui         $t6, 0x86B1
    ctx->r14 = S32(RELOC_HI16(75, 0XEBD8) << 16);
    // 0x86B042B8: lw          $t6, -0x1428($t6)
    ctx->r14 = MEM_W(ctx->r14, (int16_t)RELOC_LO16(75, 0XEBD8));
    // 0x86B042BC: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x86B042C0: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x86B042C4: addiu       $a1, $zero, -0x32
    ctx->r5 = ADD32(0, -0X32);
    // 0x86B042C8: addiu       $a2, $zero, 0x19
    ctx->r6 = ADD32(0, 0X19);
    // 0x86B042CC: addiu       $a3, $zero, 0x19
    ctx->r7 = ADD32(0, 0X19);
    // 0x86B042D0: jal         0x8001046C
    // 0x86B042D4: lw          $a0, 0x4($t6)
    ctx->r4 = MEM_W(ctx->r14, 0X4);
    func_8001046C(rdram, ctx);
        goto after_0;
    // 0x86B042D4: lw          $a0, 0x4($t6)
    ctx->r4 = MEM_W(ctx->r14, 0X4);
    after_0:
    // 0x86B042D8: lui         $t0, 0x86B1
    ctx->r8 = S32(RELOC_HI16(75, 0XEBD8) << 16);
    // 0x86B042DC: addiu       $t0, $t0, -0x1428
    ctx->r8 = ADD32(ctx->r8, (int16_t)RELOC_LO16(75, 0XEBD8));
    // 0x86B042E0: lw          $t7, 0x0($t0)
    ctx->r15 = MEM_W(ctx->r8, 0X0);
    // 0x86B042E4: addiu       $a1, $zero, 0x122
    ctx->r5 = ADD32(0, 0X122);
    // 0x86B042E8: addiu       $a2, $zero, 0x19
    ctx->r6 = ADD32(0, 0X19);
    // 0x86B042EC: sw          $v0, 0x4($t7)
    MEM_W(0X4, ctx->r15) = ctx->r2;
    // 0x86B042F0: lw          $t8, 0x0($t0)
    ctx->r24 = MEM_W(ctx->r8, 0X0);
    // 0x86B042F4: addiu       $a3, $zero, 0x19
    ctx->r7 = ADD32(0, 0X19);
    // 0x86B042F8: jal         0x8001046C
    // 0x86B042FC: lw          $a0, 0xC($t8)
    ctx->r4 = MEM_W(ctx->r24, 0XC);
    func_8001046C(rdram, ctx);
        goto after_1;
    // 0x86B042FC: lw          $a0, 0xC($t8)
    ctx->r4 = MEM_W(ctx->r24, 0XC);
    after_1:
    // 0x86B04300: lui         $t0, 0x86B1
    ctx->r8 = S32(RELOC_HI16(75, 0XEBD8) << 16);
    // 0x86B04304: addiu       $t0, $t0, -0x1428
    ctx->r8 = ADD32(ctx->r8, (int16_t)RELOC_LO16(75, 0XEBD8));
    // 0x86B04308: lw          $t9, 0x0($t0)
    ctx->r25 = MEM_W(ctx->r8, 0X0);
    // 0x86B0430C: addiu       $at, $zero, -0x32
    ctx->r1 = ADD32(0, -0X32);
    // 0x86B04310: sw          $v0, 0xC($t9)
    MEM_W(0XC, ctx->r25) = ctx->r2;
    // 0x86B04314: lw          $v1, 0x0($t0)
    ctx->r3 = MEM_W(ctx->r8, 0X0);
    // 0x86B04318: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x86B0431C: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x86B04320: lw          $t1, 0x4($v1)
    ctx->r9 = MEM_W(ctx->r3, 0X4);
    // 0x86B04324: bne         $t1, $at, L_86B04344
    if (ctx->r9 != ctx->r1) {
        // 0x86B04328: nop
    
            goto L_86B04344;
    }
    // 0x86B04328: nop

    // 0x86B0432C: lw          $t2, 0xC($v1)
    ctx->r10 = MEM_W(ctx->r3, 0XC);
    // 0x86B04330: addiu       $at, $zero, 0x122
    ctx->r1 = ADD32(0, 0X122);
    // 0x86B04334: bne         $t2, $at, L_86B04344
    if (ctx->r10 != ctx->r1) {
        // 0x86B04338: nop
    
            goto L_86B04344;
    }
    // 0x86B04338: nop

    // 0x86B0433C: b           L_86B04344
    // 0x86B04340: addiu       $v0, $zero, 0x1
    ctx->r2 = ADD32(0, 0X1);
        goto L_86B04344;
    // 0x86B04340: addiu       $v0, $zero, 0x1
    ctx->r2 = ADD32(0, 0X1);
L_86B04344:
    // 0x86B04344: jr          $ra
    // 0x86B04348: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    return;
    // 0x86B04348: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
;}
RECOMP_FUNC void func_83A009C8(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83A009C8: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x83A009CC: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x83A009D0: lui         $a0, 0x800A
    ctx->r4 = S32(0X800A << 16);
    // 0x83A009D4: lui         $a1, 0x83A0
    ctx->r5 = S32(RELOC_HI16(207, 0XB80) << 16);
    // 0x83A009D8: lw          $a1, 0xB80($a1)
    ctx->r5 = MEM_W(ctx->r5, (int16_t)RELOC_LO16(207, 0XB80));
    // 0x83A009DC: jal         0x80006498
    // 0x83A009E0: addiu       $a0, $a0, 0x7420
    ctx->r4 = ADD32(ctx->r4, 0X7420);
    func_80006498(rdram, ctx);
        goto after_0;
    // 0x83A009E0: addiu       $a0, $a0, 0x7420
    ctx->r4 = ADD32(ctx->r4, 0X7420);
    after_0:
    // 0x83A009E4: lui         $a0, 0x800A
    ctx->r4 = S32(0X800A << 16);
    // 0x83A009E8: addiu       $t6, $zero, 0x1E0
    ctx->r14 = ADD32(0, 0X1E0);
    // 0x83A009EC: ori         $t7, $zero, 0xFFFF
    ctx->r15 = 0 | 0XFFFF;
    // 0x83A009F0: sw          $t7, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r15;
    // 0x83A009F4: sw          $t6, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r14;
    // 0x83A009F8: addiu       $a0, $a0, 0x7420
    ctx->r4 = ADD32(ctx->r4, 0X7420);
    // 0x83A009FC: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x83A00A00: or          $a2, $zero, $zero
    ctx->r6 = 0 | 0;
    // 0x83A00A04: jal         0x800065B4
    // 0x83A00A08: addiu       $a3, $zero, 0x280
    ctx->r7 = ADD32(0, 0X280);
    func_800065B4(rdram, ctx);
        goto after_1;
    // 0x83A00A08: addiu       $a3, $zero, 0x280
    ctx->r7 = ADD32(0, 0X280);
    after_1:
    // 0x83A00A0C: jal         0x80007778
    // 0x83A00A10: nop

    func_80007778(rdram, ctx);
        goto after_2;
    // 0x83A00A10: nop

    after_2:
    // 0x83A00A14: jal         0x80006C6C
    // 0x83A00A18: addiu       $a0, $zero, 0x8
    ctx->r4 = ADD32(0, 0X8);
    func_80006C6C(rdram, ctx);
        goto after_3;
    // 0x83A00A18: addiu       $a0, $zero, 0x8
    ctx->r4 = ADD32(0, 0X8);
    after_3:
L_83A00A1C:
    // 0x83A00A1C: jal         0x83A00990
    // 0x83A00A20: nop

    func_83A00990(rdram, ctx);
        goto after_4;
    // 0x83A00A20: nop

    after_4:
    // 0x83A00A24: jal         0x83A00754
    // 0x83A00A28: nop

    func_83A00754(rdram, ctx);
        goto after_5;
    // 0x83A00A28: nop

    after_5:
    // 0x83A00A2C: jal         0x83A00880
    // 0x83A00A30: nop

    func_83A00880(rdram, ctx);
        goto after_6;
    // 0x83A00A30: nop

    after_6:
    // 0x83A00A34: bne         $v0, $zero, L_83A00A1C
    if (ctx->r2 != 0) {
        // 0x83A00A38: nop
    
            goto L_83A00A1C;
    }
    // 0x83A00A38: nop

    // 0x83A00A3C: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x83A00A40: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    // 0x83A00A44: jr          $ra
    // 0x83A00A48: nop

    return;
    // 0x83A00A48: nop

;}
RECOMP_FUNC void func_81207330(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x81207330: jr          $ra
    // 0x81207334: nop

    return;
    // 0x81207334: nop

;}
RECOMP_FUNC void func_84303ECC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84303ECC: addiu       $sp, $sp, -0x40
    ctx->r29 = ADD32(ctx->r29, -0X40);
    // 0x84303ED0: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x84303ED4: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x84303ED8: lw          $v0, 0x4C0($a0)
    ctx->r2 = MEM_W(ctx->r4, 0X4C0);
    // 0x84303EDC: lui         $t7, 0x8438
    ctx->r15 = S32(RELOC_HI16(259, 0X853A4) << 16);
    // 0x84303EE0: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x84303EE4: sll         $t6, $v0, 2
    ctx->r14 = S32(ctx->r2 << 2);
    // 0x84303EE8: subu        $t6, $t6, $v0
    ctx->r14 = SUB32(ctx->r14, ctx->r2);
    // 0x84303EEC: sll         $t6, $t6, 2
    ctx->r14 = S32(ctx->r14 << 2);
    // 0x84303EF0: subu        $t6, $t6, $v0
    ctx->r14 = SUB32(ctx->r14, ctx->r2);
    // 0x84303EF4: sll         $t6, $t6, 2
    ctx->r14 = S32(ctx->r14 << 2);
    // 0x84303EF8: addu        $t7, $t7, $t6
    ctx->r15 = ADD32(ctx->r15, ctx->r14);
    // 0x84303EFC: lw          $t7, 0x53A4($t7)
    ctx->r15 = MEM_W(ctx->r15, (int16_t)RELOC_LO16(259, 0X853A4));
    // 0x84303F00: sw          $t7, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r15;
    // 0x84303F04: lw          $t9, 0x65C($a0)
    ctx->r25 = MEM_W(ctx->r4, 0X65C);
    // 0x84303F08: lw          $t8, 0x724($a0)
    ctx->r24 = MEM_W(ctx->r4, 0X724);
    // 0x84303F0C: sll         $t0, $t9, 2
    ctx->r8 = S32(ctx->r25 << 2);
    // 0x84303F10: addu        $t0, $t0, $t9
    ctx->r8 = ADD32(ctx->r8, ctx->r25);
    // 0x84303F14: sll         $t0, $t0, 2
    ctx->r8 = S32(ctx->r8 << 2);
    // 0x84303F18: addu        $t0, $t0, $t9
    ctx->r8 = ADD32(ctx->r8, ctx->r25);
    // 0x84303F1C: sll         $t0, $t0, 2
    ctx->r8 = S32(ctx->r8 << 2);
    // 0x84303F20: addu        $t1, $t8, $t0
    ctx->r9 = ADD32(ctx->r24, ctx->r8);
    // 0x84303F24: addiu       $t2, $t1, 0x1C
    ctx->r10 = ADD32(ctx->r9, 0X1C);
    // 0x84303F28: jal         0x84307F00
    // 0x84303F2C: sw          $t2, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r10;
    func_84307F00(rdram, ctx);
        goto after_0;
    // 0x84303F2C: sw          $t2, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r10;
    after_0:
    // 0x84303F30: sll         $t3, $v0, 2
    ctx->r11 = S32(ctx->r2 << 2);
    // 0x84303F34: lui         $t4, 0x8438
    ctx->r12 = S32(RELOC_HI16(259, 0X84570) << 16);
    // 0x84303F38: lw          $t5, 0x34($sp)
    ctx->r13 = MEM_W(ctx->r29, 0X34);
    // 0x84303F3C: addu        $t4, $t4, $t3
    ctx->r12 = ADD32(ctx->r12, ctx->r11);
    // 0x84303F40: lw          $t4, 0x4570($t4)
    ctx->r12 = MEM_W(ctx->r12, (int16_t)RELOC_LO16(259, 0X84570));
    // 0x84303F44: sll         $t6, $t5, 4
    ctx->r14 = S32(ctx->r13 << 4);
    // 0x84303F48: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X90020) << 16);
    // 0x84303F4C: addiu       $t9, $s0, 0x654
    ctx->r25 = ADD32(ctx->r16, 0X654);
    // 0x84303F50: addu        $t7, $t4, $t6
    ctx->r15 = ADD32(ctx->r12, ctx->r14);
    // 0x84303F54: sw          $t7, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r15;
    // 0x84303F58: sw          $t9, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r25;
    // 0x84303F5C: lhu         $v1, 0x34($t9)
    ctx->r3 = MEM_HU(ctx->r25, 0X34);
    // 0x84303F60: andi        $a0, $v1, 0x2
    ctx->r4 = ctx->r3 & 0X2;
    // 0x84303F64: bne         $a0, $zero, L_84304100
    if (ctx->r4 != 0) {
        // 0x84303F68: andi        $t0, $v1, 0x4000
        ctx->r8 = ctx->r3 & 0X4000;
            goto L_84304100;
    }
    // 0x84303F68: andi        $t0, $v1, 0x4000
    ctx->r8 = ctx->r3 & 0X4000;
    // 0x84303F6C: bnel        $t0, $zero, L_84304104
    if (ctx->r8 != 0) {
        // 0x84303F70: lw          $ra, 0x1C($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X1C);
            goto L_84304104;
    }
    goto skip_0;
    // 0x84303F70: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    skip_0:
    // 0x84303F74: bne         $a0, $zero, L_84304100
    if (ctx->r4 != 0) {
        // 0x84303F78: lw          $t1, 0x30($sp)
        ctx->r9 = MEM_W(ctx->r29, 0X30);
            goto L_84304100;
    }
    // 0x84303F78: lw          $t1, 0x30($sp)
    ctx->r9 = MEM_W(ctx->r29, 0X30);
    // 0x84303F7C: lbu         $t2, 0x5($t1)
    ctx->r10 = MEM_BU(ctx->r9, 0X5);
    // 0x84303F80: lui         $a1, 0x8438
    ctx->r5 = S32(RELOC_HI16(259, 0X84590) << 16);
    // 0x84303F84: addiu       $a1, $a1, 0x4590
    ctx->r5 = ADD32(ctx->r5, (int16_t)RELOC_LO16(259, 0X84590));
    // 0x84303F88: andi        $t3, $t2, 0x7
    ctx->r11 = ctx->r10 & 0X7;
    // 0x84303F8C: beq         $t3, $zero, L_84303FF8
    if (ctx->r11 == 0) {
        // 0x84303F90: andi        $t0, $v1, 0x200
        ctx->r8 = ctx->r3 & 0X200;
            goto L_84303FF8;
    }
    // 0x84303F90: andi        $t0, $v1, 0x200
    ctx->r8 = ctx->r3 & 0X200;
    // 0x84303F94: lbu         $a0, 0x1B($s0)
    ctx->r4 = MEM_BU(ctx->r16, 0X1B);
    // 0x84303F98: jal         0x84307AE0
    // 0x84303F9C: addiu       $a2, $zero, 0x8
    ctx->r6 = ADD32(0, 0X8);
    func_84307AE0(rdram, ctx);
        goto after_1;
    // 0x84303F9C: addiu       $a2, $zero, 0x8
    ctx->r6 = ADD32(0, 0X8);
    after_1:
    // 0x84303FA0: beq         $v0, $zero, L_84303FD0
    if (ctx->r2 == 0) {
        // 0x84303FA4: nop
    
            goto L_84303FD0;
    }
    // 0x84303FA4: nop

    // 0x84303FA8: jal         0x84307F00
    // 0x84303FAC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_2;
    // 0x84303FAC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_2:
    // 0x84303FB0: sll         $t5, $v0, 2
    ctx->r13 = S32(ctx->r2 << 2);
    // 0x84303FB4: lui         $t4, 0x8438
    ctx->r12 = S32(RELOC_HI16(259, 0X84570) << 16);
    // 0x84303FB8: addu        $t4, $t4, $t5
    ctx->r12 = ADD32(ctx->r12, ctx->r13);
    // 0x84303FBC: lw          $t4, 0x4570($t4)
    ctx->r12 = MEM_W(ctx->r12, (int16_t)RELOC_LO16(259, 0X84570));
    // 0x84303FC0: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X90020) << 16);
    // 0x84303FC4: addiu       $t6, $t4, 0xAF0
    ctx->r14 = ADD32(ctx->r12, 0XAF0);
    // 0x84303FC8: b           L_84304024
    // 0x84303FCC: sw          $t6, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r14;
        goto L_84304024;
    // 0x84303FCC: sw          $t6, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r14;
L_84303FD0:
    // 0x84303FD0: jal         0x84307F00
    // 0x84303FD4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_3;
    // 0x84303FD4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_3:
    // 0x84303FD8: sll         $t7, $v0, 2
    ctx->r15 = S32(ctx->r2 << 2);
    // 0x84303FDC: lui         $t9, 0x8438
    ctx->r25 = S32(RELOC_HI16(259, 0X84570) << 16);
    // 0x84303FE0: addu        $t9, $t9, $t7
    ctx->r25 = ADD32(ctx->r25, ctx->r15);
    // 0x84303FE4: lw          $t9, 0x4570($t9)
    ctx->r25 = MEM_W(ctx->r25, (int16_t)RELOC_LO16(259, 0X84570));
    // 0x84303FE8: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X90020) << 16);
    // 0x84303FEC: addiu       $t8, $t9, 0xA50
    ctx->r24 = ADD32(ctx->r25, 0XA50);
    // 0x84303FF0: b           L_84304024
    // 0x84303FF4: sw          $t8, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r24;
        goto L_84304024;
    // 0x84303FF4: sw          $t8, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r24;
L_84303FF8:
    // 0x84303FF8: beql        $t0, $zero, L_84304028
    if (ctx->r8 == 0) {
        // 0x84303FFC: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_84304028;
    }
    goto skip_1;
    // 0x84303FFC: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    skip_1:
    // 0x84304000: jal         0x84307F00
    // 0x84304004: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_4;
    // 0x84304004: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_4:
    // 0x84304008: sll         $t1, $v0, 2
    ctx->r9 = S32(ctx->r2 << 2);
    // 0x8430400C: lui         $t2, 0x8438
    ctx->r10 = S32(RELOC_HI16(259, 0X84570) << 16);
    // 0x84304010: addu        $t2, $t2, $t1
    ctx->r10 = ADD32(ctx->r10, ctx->r9);
    // 0x84304014: lw          $t2, 0x4570($t2)
    ctx->r10 = MEM_W(ctx->r10, (int16_t)RELOC_LO16(259, 0X84570));
    // 0x84304018: lui         $at, 0x8439
    ctx->r1 = S32(RELOC_HI16(259, 0X90020) << 16);
    // 0x8430401C: addiu       $t3, $t2, 0xB00
    ctx->r11 = ADD32(ctx->r10, 0XB00);
    // 0x84304020: sw          $t3, 0x20($at)
    MEM_W((int16_t)RELOC_LO16(259, 0X90020), ctx->r1) = ctx->r11;
L_84304024:
    // 0x84304024: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
L_84304028:
    // 0x84304028: jal         0x80017464
    // 0x8430402C: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    func_80017464(rdram, ctx);
        goto after_5;
    // 0x8430402C: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    after_5:
    // 0x84304030: lui         $t5, 0x8439
    ctx->r13 = S32(RELOC_HI16(259, 0X90020) << 16);
    // 0x84304034: lw          $t5, 0x20($t5)
    ctx->r13 = MEM_W(ctx->r13, (int16_t)RELOC_LO16(259, 0X90020));
    // 0x84304038: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8430403C: jal         0x8001BD04
    // 0x84304040: lbu         $a1, 0x0($t5)
    ctx->r5 = MEM_BU(ctx->r13, 0X0);
    func_8001BD04(rdram, ctx);
        goto after_6;
    // 0x84304040: lbu         $a1, 0x0($t5)
    ctx->r5 = MEM_BU(ctx->r13, 0X0);
    after_6:
    // 0x84304044: lw          $t4, 0x24($sp)
    ctx->r12 = MEM_W(ctx->r29, 0X24);
    // 0x84304048: lhu         $t6, 0x34($t4)
    ctx->r14 = MEM_HU(ctx->r12, 0X34);
    // 0x8430404C: andi        $t7, $t6, 0x200
    ctx->r15 = ctx->r14 & 0X200;
    // 0x84304050: beq         $t7, $zero, L_843040B0
    if (ctx->r15 == 0) {
        // 0x84304054: nop
    
            goto L_843040B0;
    }
    // 0x84304054: nop

    // 0x84304058: jal         0x84307B60
    // 0x8430405C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307B60(rdram, ctx);
        goto after_7;
    // 0x8430405C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_7:
    // 0x84304060: beq         $v0, $zero, L_8430408C
    if (ctx->r2 == 0) {
        // 0x84304064: nop
    
            goto L_8430408C;
    }
    // 0x84304064: nop

    // 0x84304068: jal         0x84307F00
    // 0x8430406C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_8;
    // 0x8430406C: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_8:
    // 0x84304070: andi        $a0, $v0, 0xFF
    ctx->r4 = ctx->r2 & 0XFF;
    // 0x84304074: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x84304078: addiu       $a2, $zero, 0xC8
    ctx->r6 = ADD32(0, 0XC8);
    // 0x8430407C: jal         0x80048060
    // 0x84304080: addiu       $a3, $zero, 0x1A
    ctx->r7 = ADD32(0, 0X1A);
    func_80048060(rdram, ctx);
        goto after_9;
    // 0x84304080: addiu       $a3, $zero, 0x1A
    ctx->r7 = ADD32(0, 0X1A);
    after_9:
    // 0x84304084: b           L_84304104
    // 0x84304088: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
        goto L_84304104;
    // 0x84304088: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
L_8430408C:
    // 0x8430408C: jal         0x84307F00
    // 0x84304090: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_10;
    // 0x84304090: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_10:
    // 0x84304094: andi        $a0, $v0, 0xFF
    ctx->r4 = ctx->r2 & 0XFF;
    // 0x84304098: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x8430409C: lh          $a2, 0x1A($s0)
    ctx->r6 = MEM_H(ctx->r16, 0X1A);
    // 0x843040A0: jal         0x80048060
    // 0x843040A4: addiu       $a3, $zero, 0x1A
    ctx->r7 = ADD32(0, 0X1A);
    func_80048060(rdram, ctx);
        goto after_11;
    // 0x843040A4: addiu       $a3, $zero, 0x1A
    ctx->r7 = ADD32(0, 0X1A);
    after_11:
    // 0x843040A8: b           L_84304104
    // 0x843040AC: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
        goto L_84304104;
    // 0x843040AC: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
L_843040B0:
    // 0x843040B0: jal         0x84307B60
    // 0x843040B4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307B60(rdram, ctx);
        goto after_12;
    // 0x843040B4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_12:
    // 0x843040B8: beq         $v0, $zero, L_843040E4
    if (ctx->r2 == 0) {
        // 0x843040BC: nop
    
            goto L_843040E4;
    }
    // 0x843040BC: nop

    // 0x843040C0: jal         0x84307F00
    // 0x843040C4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_13;
    // 0x843040C4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_13:
    // 0x843040C8: andi        $a0, $v0, 0xFF
    ctx->r4 = ctx->r2 & 0XFF;
    // 0x843040CC: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x843040D0: addiu       $a2, $zero, 0xC8
    ctx->r6 = ADD32(0, 0XC8);
    // 0x843040D4: jal         0x80048060
    // 0x843040D8: addiu       $a3, $zero, 0xA
    ctx->r7 = ADD32(0, 0XA);
    func_80048060(rdram, ctx);
        goto after_14;
    // 0x843040D8: addiu       $a3, $zero, 0xA
    ctx->r7 = ADD32(0, 0XA);
    after_14:
    // 0x843040DC: b           L_84304104
    // 0x843040E0: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
        goto L_84304104;
    // 0x843040E0: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
L_843040E4:
    // 0x843040E4: jal         0x84307F00
    // 0x843040E8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    func_84307F00(rdram, ctx);
        goto after_15;
    // 0x843040E8: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    after_15:
    // 0x843040EC: andi        $a0, $v0, 0xFF
    ctx->r4 = ctx->r2 & 0XFF;
    // 0x843040F0: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x843040F4: lh          $a2, 0x1A($s0)
    ctx->r6 = MEM_H(ctx->r16, 0X1A);
    // 0x843040F8: jal         0x80048060
    // 0x843040FC: addiu       $a3, $zero, 0xA
    ctx->r7 = ADD32(0, 0XA);
    func_80048060(rdram, ctx);
        goto after_16;
    // 0x843040FC: addiu       $a3, $zero, 0xA
    ctx->r7 = ADD32(0, 0XA);
    after_16:
L_84304100:
    // 0x84304100: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
L_84304104:
    // 0x84304104: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x84304108: addiu       $sp, $sp, 0x40
    ctx->r29 = ADD32(ctx->r29, 0X40);
    // 0x8430410C: jr          $ra
    // 0x84304110: nop

    return;
    // 0x84304110: nop

;}
RECOMP_FUNC void func_83700098(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83700098: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x8370009C: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x837000A0: jal         0x800079C4
    // 0x837000A4: nop

    func_800079C4(rdram, ctx);
        goto after_0;
    // 0x837000A4: nop

    after_0:
    // 0x837000A8: lui         $v0, 0x8370
    ctx->r2 = S32(RELOC_HI16(195, 0X4B0) << 16);
    // 0x837000AC: lw          $v0, 0x4B0($v0)
    ctx->r2 = MEM_W(ctx->r2, (int16_t)RELOC_LO16(195, 0X4B0));
    // 0x837000B0: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
    // 0x837000B4: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x837000B8: lhu         $t6, 0x0($v0)
    ctx->r14 = MEM_HU(ctx->r2, 0X0);
    // 0x837000BC: or          $a2, $zero, $zero
    ctx->r6 = 0 | 0;
    // 0x837000C0: addiu       $t9, $zero, 0x1
    ctx->r25 = ADD32(0, 0X1);
    // 0x837000C4: bne         $t6, $at, L_837000EC
    if (ctx->r14 != ctx->r1) {
        // 0x837000C8: nop
    
            goto L_837000EC;
    }
    // 0x837000C8: nop

    // 0x837000CC: lw          $t7, 0x8($v0)
    ctx->r15 = MEM_W(ctx->r2, 0X8);
    // 0x837000D0: lh          $t8, 0x6($v0)
    ctx->r24 = MEM_H(ctx->r2, 0X6);
    // 0x837000D4: lh          $a3, 0x4($v0)
    ctx->r7 = MEM_H(ctx->r2, 0X4);
    // 0x837000D8: lw          $a0, 0x8($t7)
    ctx->r4 = MEM_W(ctx->r15, 0X8);
    // 0x837000DC: sw          $zero, 0x18($sp)
    MEM_W(0X18, ctx->r29) = 0;
    // 0x837000E0: sw          $t9, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r25;
    // 0x837000E4: jal         0x834018C0
    // 0x837000E8: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    func_834018C0(rdram, ctx);
        goto after_1;
    // 0x837000E8: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    after_1:
L_837000EC:
    // 0x837000EC: jal         0x80007778
    // 0x837000F0: nop

    func_80007778(rdram, ctx);
        goto after_2;
    // 0x837000F0: nop

    after_2:
    // 0x837000F4: lui         $t0, 0x8370
    ctx->r8 = S32(RELOC_HI16(195, 0X4B4) << 16);
    // 0x837000F8: lh          $t0, 0x4B4($t0)
    ctx->r8 = MEM_H(ctx->r8, (int16_t)RELOC_LO16(195, 0X4B4));
    // 0x837000FC: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
    // 0x83700100: lui         $at, 0x8370
    ctx->r1 = S32(RELOC_HI16(195, 0X4B4) << 16);
    // 0x83700104: addiu       $t1, $t0, 0x1000
    ctx->r9 = ADD32(ctx->r8, 0X1000);
    // 0x83700108: sh          $t1, 0x4B4($at)
    MEM_H((int16_t)RELOC_LO16(195, 0X4B4), ctx->r1) = ctx->r9;
    // 0x8370010C: jr          $ra
    // 0x83700110: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    return;
    // 0x83700110: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
;}
RECOMP_FUNC void func_83600288(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83600288: addiu       $sp, $sp, -0x30
    ctx->r29 = ADD32(ctx->r29, -0X30);
    // 0x8360028C: sw          $s2, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r18;
    // 0x83600290: sw          $s1, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r17;
    // 0x83600294: sw          $s3, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r19;
    // 0x83600298: sw          $s0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r16;
    // 0x8360029C: lui         $s1, 0x8340
    ctx->r17 = S32(RELOC_HI16(183, 0X2EE0) << 16);
    // 0x836002A0: lui         $s2, 0x8340
    ctx->r18 = S32(RELOC_HI16(183, 0X3C00) << 16);
    // 0x836002A4: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x836002A8: sw          $zero, 0x28($sp)
    MEM_W(0X28, ctx->r29) = 0;
    // 0x836002AC: addiu       $s2, $s2, 0x3C00
    ctx->r18 = ADD32(ctx->r18, (int16_t)RELOC_LO16(183, 0X3C00));
    // 0x836002B0: addiu       $s1, $s1, 0x2EE0
    ctx->r17 = ADD32(ctx->r17, (int16_t)RELOC_LO16(183, 0X2EE0));
    // 0x836002B4: or          $s0, $zero, $zero
    ctx->r16 = 0 | 0;
    // 0x836002B8: addiu       $s3, $zero, 0x18
    ctx->r19 = ADD32(0, 0X18);
L_836002BC:
    // 0x836002BC: jal         0x800318C4
    // 0x836002C0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    func_800318C4(rdram, ctx);
        goto after_0;
    // 0x836002C0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    after_0:
    // 0x836002C4: beq         $v0, $zero, L_836002E4
    if (ctx->r2 == 0) {
        // 0x836002C8: sll         $t6, $s0, 2
        ctx->r14 = S32(ctx->r16 << 2);
            goto L_836002E4;
    }
    // 0x836002C8: sll         $t6, $s0, 2
    ctx->r14 = S32(ctx->r16 << 2);
    // 0x836002CC: addu        $t7, $s2, $t6
    ctx->r15 = ADD32(ctx->r18, ctx->r14);
    // 0x836002D0: lw          $t8, 0x0($t7)
    ctx->r24 = MEM_W(ctx->r15, 0X0);
    // 0x836002D4: bne         $t8, $zero, L_836002E4
    if (ctx->r24 != 0) {
        // 0x836002D8: addiu       $t9, $zero, 0x1
        ctx->r25 = ADD32(0, 0X1);
            goto L_836002E4;
    }
    // 0x836002D8: addiu       $t9, $zero, 0x1
    ctx->r25 = ADD32(0, 0X1);
    // 0x836002DC: b           L_836002F0
    // 0x836002E0: sw          $t9, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r25;
        goto L_836002F0;
    // 0x836002E0: sw          $t9, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r25;
L_836002E4:
    // 0x836002E4: addiu       $s0, $s0, 0x1
    ctx->r16 = ADD32(ctx->r16, 0X1);
    // 0x836002E8: bne         $s0, $s3, L_836002BC
    if (ctx->r16 != ctx->r19) {
        // 0x836002EC: addiu       $s1, $s1, 0x8C
        ctx->r17 = ADD32(ctx->r17, 0X8C);
            goto L_836002BC;
    }
    // 0x836002EC: addiu       $s1, $s1, 0x8C
    ctx->r17 = ADD32(ctx->r17, 0X8C);
L_836002F0:
    // 0x836002F0: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
    // 0x836002F4: lw          $v0, 0x28($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X28);
    // 0x836002F8: lw          $s0, 0x14($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X14);
    // 0x836002FC: lw          $s1, 0x18($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X18);
    // 0x83600300: lw          $s2, 0x1C($sp)
    ctx->r18 = MEM_W(ctx->r29, 0X1C);
    // 0x83600304: lw          $s3, 0x20($sp)
    ctx->r19 = MEM_W(ctx->r29, 0X20);
    // 0x83600308: jr          $ra
    // 0x8360030C: addiu       $sp, $sp, 0x30
    ctx->r29 = ADD32(ctx->r29, 0X30);
    return;
    // 0x8360030C: addiu       $sp, $sp, 0x30
    ctx->r29 = ADD32(ctx->r29, 0X30);
;}
RECOMP_FUNC void func_80022ACC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80022ACC: bne         $a0, $zero, L_80022ADC
    if (ctx->r4 != 0) {
        // 0x80022AD0: lui         $v0, 0x8007
        ctx->r2 = S32(0X8007 << 16);
            goto L_80022ADC;
    }
    // 0x80022AD0: lui         $v0, 0x8007
    ctx->r2 = S32(0X8007 << 16);
    // 0x80022AD4: jr          $ra
    // 0x80022AD8: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    return;
    // 0x80022AD8: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
L_80022ADC:
    // 0x80022ADC: addu        $v0, $v0, $a0
    ctx->r2 = ADD32(ctx->r2, ctx->r4);
    // 0x80022AE0: lbu         $v0, 0x3597($v0)
    ctx->r2 = MEM_BU(ctx->r2, 0X3597);
    // 0x80022AE4: addiu       $v0, $v0, 0x1
    ctx->r2 = ADD32(ctx->r2, 0X1);
    // 0x80022AE8: jr          $ra
    // 0x80022AEC: nop

    return;
    // 0x80022AEC: nop

;}
RECOMP_FUNC void func_81409918(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x81409918: lui         $at, 0x8141
    ctx->r1 = S32(RELOC_HI16(147, 0XE62C) << 16);
    // 0x8140991C: mtc1        $a1, $f12
    ctx->f12.u32l = ctx->r5;
    // 0x81409920: lwc1        $f4, -0x19D4($at)
    ctx->f4.u32l = MEM_W(ctx->r1, (int16_t)RELOC_LO16(147, 0XE62C));
    // 0x81409924: mul.s       $f6, $f12, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f12.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f6.fl = MUL_S(ctx->f12.fl, ctx->f4.fl);
    // 0x81409928: jr          $ra
    // 0x8140992C: swc1        $f6, 0x58($a0)
    MEM_W(0X58, ctx->r4) = ctx->f6.u32l;
    return;
    // 0x8140992C: swc1        $f6, 0x58($a0)
    MEM_W(0X58, ctx->r4) = ctx->f6.u32l;
;}
RECOMP_FUNC void func_86102F30(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86102F30: addiu       $t6, $zero, 0xC
    ctx->r14 = ADD32(0, 0XC);
    // 0x86102F34: lui         $at, 0x8610
    ctx->r1 = S32(RELOC_HI16(35, 0X5498) << 16);
    // 0x86102F38: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x86102F3C: sw          $t6, 0x5498($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5498), ctx->r1) = ctx->r14;
    // 0x86102F40: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x86102F44: lui         $at, 0x8610
    ctx->r1 = S32(RELOC_HI16(35, 0X549C) << 16);
    // 0x86102F48: lui         $a0, 0x8610
    ctx->r4 = S32(RELOC_HI16(35, 0X5BD0) << 16);
    // 0x86102F4C: sw          $zero, 0x549C($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X549C), ctx->r1) = 0;
    // 0x86102F50: addiu       $a0, $a0, 0x5BD0
    ctx->r4 = ADD32(ctx->r4, (int16_t)RELOC_LO16(35, 0X5BD0));
    // 0x86102F54: jal         0x8001BD04
    // 0x86102F58: addiu       $a1, $zero, 0x4
    ctx->r5 = ADD32(0, 0X4);
    func_8001BD04(rdram, ctx);
        goto after_0;
    // 0x86102F58: addiu       $a1, $zero, 0x4
    ctx->r5 = ADD32(0, 0X4);
    after_0:
    // 0x86102F5C: lui         $a0, 0x8610
    ctx->r4 = S32(RELOC_HI16(35, 0X5BD0) << 16);
    // 0x86102F60: jal         0x80017788
    // 0x86102F64: addiu       $a0, $a0, 0x5BD0
    ctx->r4 = ADD32(ctx->r4, (int16_t)RELOC_LO16(35, 0X5BD0));
    func_80017788(rdram, ctx);
        goto after_1;
    // 0x86102F64: addiu       $a0, $a0, 0x5BD0
    ctx->r4 = ADD32(ctx->r4, (int16_t)RELOC_LO16(35, 0X5BD0));
    after_1:
    // 0x86102F68: lui         $at, 0x8610
    ctx->r1 = S32(RELOC_HI16(35, 0X5C18) << 16);
    // 0x86102F6C: sw          $zero, 0x5C18($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5C18), ctx->r1) = 0;
    // 0x86102F70: lui         $t7, 0x8610
    ctx->r15 = S32(RELOC_HI16(35, 0X54C0) << 16);
    // 0x86102F74: lui         $v0, 0x8610
    ctx->r2 = S32(RELOC_HI16(35, 0X5BC4) << 16);
    // 0x86102F78: addiu       $t7, $t7, 0x54C0
    ctx->r15 = ADD32(ctx->r15, (int16_t)RELOC_LO16(35, 0X54C0));
    // 0x86102F7C: lui         $at, 0x8610
    ctx->r1 = S32(RELOC_HI16(35, 0X5BC4) << 16);
    // 0x86102F80: addiu       $v0, $v0, 0x5BC4
    ctx->r2 = ADD32(ctx->r2, (int16_t)RELOC_LO16(35, 0X5BC4));
    // 0x86102F84: sw          $t7, 0x5BC4($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5BC4), ctx->r1) = ctx->r15;
    // 0x86102F88: lw          $t8, 0x0($v0)
    ctx->r24 = MEM_W(ctx->r2, 0X0);
    // 0x86102F8C: lui         $t9, 0x8610
    ctx->r25 = S32(RELOC_HI16(35, 0X5680) << 16);
    // 0x86102F90: addiu       $t9, $t9, 0x5680
    ctx->r25 = ADD32(ctx->r25, (int16_t)RELOC_LO16(35, 0X5680));
    // 0x86102F94: sh          $zero, 0x1A6($t8)
    MEM_H(0X1A6, ctx->r24) = 0;
    // 0x86102F98: sw          $t9, 0x5BC4($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5BC4), ctx->r1) = ctx->r25;
    // 0x86102F9C: lw          $t0, 0x0($v0)
    ctx->r8 = MEM_W(ctx->r2, 0X0);
    // 0x86102FA0: lui         $t1, 0x8610
    ctx->r9 = S32(RELOC_HI16(35, 0X5840) << 16);
    // 0x86102FA4: addiu       $t1, $t1, 0x5840
    ctx->r9 = ADD32(ctx->r9, (int16_t)RELOC_LO16(35, 0X5840));
    // 0x86102FA8: sh          $zero, 0x1A6($t0)
    MEM_H(0X1A6, ctx->r8) = 0;
    // 0x86102FAC: sw          $t1, 0x5BC4($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5BC4), ctx->r1) = ctx->r9;
    // 0x86102FB0: lw          $t2, 0x0($v0)
    ctx->r10 = MEM_W(ctx->r2, 0X0);
    // 0x86102FB4: lui         $t3, 0x8610
    ctx->r11 = S32(RELOC_HI16(35, 0X5A00) << 16);
    // 0x86102FB8: addiu       $t3, $t3, 0x5A00
    ctx->r11 = ADD32(ctx->r11, (int16_t)RELOC_LO16(35, 0X5A00));
    // 0x86102FBC: sh          $zero, 0x1A6($t2)
    MEM_H(0X1A6, ctx->r10) = 0;
    // 0x86102FC0: sw          $t3, 0x5BC4($at)
    MEM_W((int16_t)RELOC_LO16(35, 0X5BC4), ctx->r1) = ctx->r11;
    // 0x86102FC4: lw          $t4, 0x0($v0)
    ctx->r12 = MEM_W(ctx->r2, 0X0);
    // 0x86102FC8: sh          $zero, 0x1A6($t4)
    MEM_H(0X1A6, ctx->r12) = 0;
    // 0x86102FCC: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x86102FD0: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x86102FD4: jr          $ra
    // 0x86102FD8: nop

    return;
    // 0x86102FD8: nop

;}
RECOMP_FUNC void func_885065E0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x885065E0: addiu       $sp, $sp, -0x60
    ctx->r29 = ADD32(ctx->r29, -0X60);
    // 0x885065E4: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x885065E8: sw          $s0, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r16;
    // 0x885065EC: sw          $a1, 0x64($sp)
    MEM_W(0X64, ctx->r29) = ctx->r5;
    // 0x885065F0: sw          $zero, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = 0;
    // 0x885065F4: lw          $v0, 0x2C($a0)
    ctx->r2 = MEM_W(ctx->r4, 0X2C);
    // 0x885065F8: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x885065FC: or          $t4, $zero, $zero
    ctx->r12 = 0 | 0;
    // 0x88506600: beq         $v0, $zero, L_88506614
    if (ctx->r2 == 0) {
        // 0x88506604: nop
    
            goto L_88506614;
    }
    // 0x88506604: nop

    // 0x88506608: lw          $v1, 0x8($v0)
    ctx->r3 = MEM_W(ctx->r2, 0X8);
    // 0x8850660C: bnel        $v1, $zero, L_88506620
    if (ctx->r3 != 0) {
        // 0x88506610: lh          $t0, 0x48($s0)
        ctx->r8 = MEM_H(ctx->r16, 0X48);
            goto L_88506620;
    }
    goto skip_0;
    // 0x88506610: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    skip_0:
L_88506614:
    // 0x88506614: b           L_88506BE8
    // 0x88506618: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
        goto L_88506BE8;
    // 0x88506618: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x8850661C: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
L_88506620:
    // 0x88506620: lw          $v0, 0x38($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X38);
    // 0x88506624: sw          $t4, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r12;
    // 0x88506628: addu        $t6, $v1, $t0
    ctx->r14 = ADD32(ctx->r3, ctx->r8);
    // 0x8850662C: addiu       $t7, $t6, -0x1
    ctx->r15 = ADD32(ctx->r14, -0X1);
    // 0x88506630: div         $zero, $t7, $t0
    lo = S32(S64(S32(ctx->r15)) / S64(S32(ctx->r8))); hi = S32(S64(S32(ctx->r15)) % S64(S32(ctx->r8)));
    // 0x88506634: mflo        $t2
    ctx->r10 = lo;
    // 0x88506638: sw          $t2, 0x48($sp)
    MEM_W(0X48, ctx->r29) = ctx->r10;
    // 0x8850663C: bne         $t0, $zero, L_88506648
    if (ctx->r8 != 0) {
        // 0x88506640: nop
    
            goto L_88506648;
    }
    // 0x88506640: nop

    // 0x88506644: break       7
    do_break(2286970436);
L_88506648:
    // 0x88506648: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x8850664C: bne         $t0, $at, L_88506660
    if (ctx->r8 != ctx->r1) {
        // 0x88506650: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_88506660;
    }
    // 0x88506650: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x88506654: bne         $t7, $at, L_88506660
    if (ctx->r15 != ctx->r1) {
        // 0x88506658: nop
    
            goto L_88506660;
    }
    // 0x88506658: nop

    // 0x8850665C: break       6
    do_break(2286970460);
L_88506660:
    // 0x88506660: div         $zero, $v0, $t0
    lo = S32(S64(S32(ctx->r2)) / S64(S32(ctx->r8))); hi = S32(S64(S32(ctx->r2)) % S64(S32(ctx->r8)));
    // 0x88506664: mflo        $ra
    ctx->r31 = lo;
    // 0x88506668: mfhi        $t5
    ctx->r13 = hi;
    // 0x8850666C: sw          $ra, 0x54($sp)
    MEM_W(0X54, ctx->r29) = ctx->r31;
    // 0x88506670: bne         $t0, $zero, L_8850667C
    if (ctx->r8 != 0) {
        // 0x88506674: nop
    
            goto L_8850667C;
    }
    // 0x88506674: nop

    // 0x88506678: break       7
    do_break(2286970488);
L_8850667C:
    // 0x8850667C: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x88506680: bne         $t0, $at, L_88506694
    if (ctx->r8 != ctx->r1) {
        // 0x88506684: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_88506694;
    }
    // 0x88506684: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x88506688: bne         $v0, $at, L_88506694
    if (ctx->r2 != ctx->r1) {
        // 0x8850668C: nop
    
            goto L_88506694;
    }
    // 0x8850668C: nop

    // 0x88506690: break       6
    do_break(2286970512);
L_88506694:
    // 0x88506694: sw          $t5, 0x58($sp)
    MEM_W(0X58, ctx->r29) = ctx->r13;
    // 0x88506698: jal         0x8001F750
    // 0x8850669C: nop

    func_8001F750(rdram, ctx);
        goto after_0;
    // 0x8850669C: nop

    after_0:
    // 0x885066A0: andi        $t8, $v0, 0xFFFF
    ctx->r24 = ctx->r2 & 0XFFFF;
    // 0x885066A4: addiu       $at, $zero, 0x800
    ctx->r1 = ADD32(0, 0X800);
    // 0x885066A8: lw          $t2, 0x48($sp)
    ctx->r10 = MEM_W(ctx->r29, 0X48);
    // 0x885066AC: lw          $t4, 0x34($sp)
    ctx->r12 = MEM_W(ctx->r29, 0X34);
    // 0x885066B0: lw          $t5, 0x58($sp)
    ctx->r13 = MEM_W(ctx->r29, 0X58);
    // 0x885066B4: lw          $ra, 0x54($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X54);
    // 0x885066B8: sw          $t8, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r24;
    // 0x885066BC: bne         $t8, $at, L_885067C8
    if (ctx->r24 != ctx->r1) {
        // 0x885066C0: or          $t9, $t8, $zero
        ctx->r25 = ctx->r24 | 0;
            goto L_885067C8;
    }
    // 0x885066C0: or          $t9, $t8, $zero
    ctx->r25 = ctx->r24 | 0;
    // 0x885066C4: addiu       $t3, $t2, -0x1
    ctx->r11 = ADD32(ctx->r10, -0X1);
    // 0x885066C8: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    // 0x885066CC: blez        $t3, L_88506788
    if (SIGNED(ctx->r11) <= 0) {
        // 0x885066D0: or          $t1, $ra, $zero
        ctx->r9 = ctx->r31 | 0;
            goto L_88506788;
    }
    // 0x885066D0: or          $t1, $ra, $zero
    ctx->r9 = ctx->r31 | 0;
    // 0x885066D4: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    // 0x885066D8: lh          $t5, 0x4C($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X4C);
    // 0x885066DC: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
L_885066E0:
    // 0x885066E0: bne         $t1, $zero, L_885066F0
    if (ctx->r9 != 0) {
        // 0x885066E4: or          $a3, $t5, $zero
        ctx->r7 = ctx->r13 | 0;
            goto L_885066F0;
    }
    // 0x885066E4: or          $a3, $t5, $zero
    ctx->r7 = ctx->r13 | 0;
    // 0x885066E8: b           L_885066F4
    // 0x885066EC: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
        goto L_885066F4;
    // 0x885066EC: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
L_885066F0:
    // 0x885066F0: or          $v0, $t1, $zero
    ctx->r2 = ctx->r9 | 0;
L_885066F4:
    // 0x885066F4: blez        $t0, L_88506768
    if (SIGNED(ctx->r8) <= 0) {
        // 0x885066F8: addiu       $t1, $v0, -0x1
        ctx->r9 = ADD32(ctx->r2, -0X1);
            goto L_88506768;
    }
    // 0x885066F8: addiu       $t1, $v0, -0x1
    ctx->r9 = ADD32(ctx->r2, -0X1);
    // 0x885066FC: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506700: lw          $t6, 0x2C($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X2C);
    // 0x88506704: lw          $v1, 0x8($t6)
    ctx->r3 = MEM_W(ctx->r14, 0X8);
    // 0x88506708: mflo        $a2
    ctx->r6 = lo;
    // 0x8850670C: nop

    // 0x88506710: nop

L_88506714:
    // 0x88506714: addu        $v0, $a2, $a3
    ctx->r2 = ADD32(ctx->r6, ctx->r7);
    // 0x88506718: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    // 0x8850671C: beq         $at, $zero, L_88506748
    if (ctx->r1 == 0) {
        // 0x88506720: nop
    
            goto L_88506748;
    }
    // 0x88506720: nop

    // 0x88506724: lw          $t7, 0x34($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X34);
    // 0x88506728: sll         $t8, $v0, 1
    ctx->r24 = S32(ctx->r2 << 1);
    // 0x8850672C: addu        $t9, $t7, $t8
    ctx->r25 = ADD32(ctx->r15, ctx->r24);
    // 0x88506730: lhu         $t6, 0x0($t9)
    ctx->r14 = MEM_HU(ctx->r25, 0X0);
    // 0x88506734: andi        $t7, $t6, 0x4
    ctx->r15 = ctx->r14 & 0X4;
    // 0x88506738: bne         $t7, $zero, L_88506748
    if (ctx->r15 != 0) {
        // 0x8850673C: nop
    
            goto L_88506748;
    }
    // 0x8850673C: nop

    // 0x88506740: b           L_88506768
    // 0x88506744: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
        goto L_88506768;
    // 0x88506744: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
L_88506748:
    // 0x88506748: bne         $a3, $zero, L_88506758
    if (ctx->r7 != 0) {
        // 0x8850674C: addiu       $a1, $a1, 0x1
        ctx->r5 = ADD32(ctx->r5, 0X1);
            goto L_88506758;
    }
    // 0x8850674C: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
    // 0x88506750: b           L_8850675C
    // 0x88506754: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
        goto L_8850675C;
    // 0x88506754: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
L_88506758:
    // 0x88506758: or          $v0, $a3, $zero
    ctx->r2 = ctx->r7 | 0;
L_8850675C:
    // 0x8850675C: slt         $at, $a1, $t0
    ctx->r1 = SIGNED(ctx->r5) < SIGNED(ctx->r8) ? 1 : 0;
    // 0x88506760: bne         $at, $zero, L_88506714
    if (ctx->r1 != 0) {
        // 0x88506764: addiu       $a3, $v0, -0x1
        ctx->r7 = ADD32(ctx->r2, -0X1);
            goto L_88506714;
    }
    // 0x88506764: addiu       $a3, $v0, -0x1
    ctx->r7 = ADD32(ctx->r2, -0X1);
L_88506768:
    // 0x88506768: beql        $t4, $zero, L_8850677C
    if (ctx->r12 == 0) {
        // 0x8850676C: addiu       $a0, $a0, 0x1
        ctx->r4 = ADD32(ctx->r4, 0X1);
            goto L_8850677C;
    }
    goto skip_1;
    // 0x8850676C: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
    skip_1:
    // 0x88506770: b           L_88506788
    // 0x88506774: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
        goto L_88506788;
    // 0x88506774: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    // 0x88506778: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
L_8850677C:
    // 0x8850677C: bnel        $a0, $t3, L_885066E0
    if (ctx->r4 != ctx->r11) {
        // 0x88506780: or          $a1, $zero, $zero
        ctx->r5 = 0 | 0;
            goto L_885066E0;
    }
    goto skip_2;
    // 0x88506780: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    skip_2:
    // 0x88506784: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_88506788:
    // 0x88506788: lhu         $t8, 0x28($s0)
    ctx->r24 = MEM_HU(ctx->r16, 0X28);
    // 0x8850678C: lw          $a3, 0x50($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X50);
    // 0x88506790: andi        $t9, $t8, 0x200
    ctx->r25 = ctx->r24 & 0X200;
    // 0x88506794: beql        $t9, $zero, L_885067C0
    if (ctx->r25 == 0) {
        // 0x88506798: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885067C0;
    }
    goto skip_3;
    // 0x88506798: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_3:
    // 0x8850679C: beql        $t4, $zero, L_885067B4
    if (ctx->r12 == 0) {
        // 0x885067A0: addiu       $t6, $zero, 0x8
        ctx->r14 = ADD32(0, 0X8);
            goto L_885067B4;
    }
    goto skip_4;
    // 0x885067A0: addiu       $t6, $zero, 0x8
    ctx->r14 = ADD32(0, 0X8);
    skip_4:
    // 0x885067A4: slt         $at, $ra, $t1
    ctx->r1 = SIGNED(ctx->r31) < SIGNED(ctx->r9) ? 1 : 0;
    // 0x885067A8: beql        $at, $zero, L_885067C0
    if (ctx->r1 == 0) {
        // 0x885067AC: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885067C0;
    }
    goto skip_5;
    // 0x885067AC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_5:
    // 0x885067B0: addiu       $t6, $zero, 0x8
    ctx->r14 = ADD32(0, 0X8);
L_885067B4:
    // 0x885067B4: sw          $t6, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = ctx->r14;
    // 0x885067B8: or          $t4, $zero, $zero
    ctx->r12 = 0 | 0;
    // 0x885067BC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_885067C0:
    // 0x885067C0: b           L_88506AFC
    // 0x885067C4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
        goto L_88506AFC;
    // 0x885067C4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
L_885067C8:
    // 0x885067C8: lw          $t7, 0x24($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X24);
    // 0x885067CC: addiu       $at, $zero, 0x400
    ctx->r1 = ADD32(0, 0X400);
    // 0x885067D0: or          $t1, $ra, $zero
    ctx->r9 = ctx->r31 | 0;
    // 0x885067D4: bnel        $t7, $at, L_885068E0
    if (ctx->r15 != ctx->r1) {
        // 0x885067D8: lw          $t9, 0x24($sp)
        ctx->r25 = MEM_W(ctx->r29, 0X24);
            goto L_885068E0;
    }
    goto skip_6;
    // 0x885067D8: lw          $t9, 0x24($sp)
    ctx->r25 = MEM_W(ctx->r29, 0X24);
    skip_6:
    // 0x885067DC: addiu       $t3, $t2, -0x1
    ctx->r11 = ADD32(ctx->r10, -0X1);
    // 0x885067E0: blez        $t3, L_8850689C
    if (SIGNED(ctx->r11) <= 0) {
        // 0x885067E4: or          $a0, $zero, $zero
        ctx->r4 = 0 | 0;
            goto L_8850689C;
    }
    // 0x885067E4: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    // 0x885067E8: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    // 0x885067EC: lh          $t5, 0x4C($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X4C);
    // 0x885067F0: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
L_885067F4:
    // 0x885067F4: bne         $t1, $t3, L_88506804
    if (ctx->r9 != ctx->r11) {
        // 0x885067F8: or          $a3, $t5, $zero
        ctx->r7 = ctx->r13 | 0;
            goto L_88506804;
    }
    // 0x885067F8: or          $a3, $t5, $zero
    ctx->r7 = ctx->r13 | 0;
    // 0x885067FC: b           L_88506808
    // 0x88506800: or          $t1, $zero, $zero
    ctx->r9 = 0 | 0;
        goto L_88506808;
    // 0x88506800: or          $t1, $zero, $zero
    ctx->r9 = 0 | 0;
L_88506804:
    // 0x88506804: addiu       $t1, $t1, 0x1
    ctx->r9 = ADD32(ctx->r9, 0X1);
L_88506808:
    // 0x88506808: blez        $t0, L_8850687C
    if (SIGNED(ctx->r8) <= 0) {
        // 0x8850680C: nop
    
            goto L_8850687C;
    }
    // 0x8850680C: nop

    // 0x88506810: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506814: lw          $t8, 0x2C($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X2C);
    // 0x88506818: lw          $v1, 0x8($t8)
    ctx->r3 = MEM_W(ctx->r24, 0X8);
    // 0x8850681C: mflo        $a2
    ctx->r6 = lo;
    // 0x88506820: nop

    // 0x88506824: nop

L_88506828:
    // 0x88506828: addu        $v0, $a2, $a3
    ctx->r2 = ADD32(ctx->r6, ctx->r7);
    // 0x8850682C: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    // 0x88506830: beq         $at, $zero, L_8850685C
    if (ctx->r1 == 0) {
        // 0x88506834: nop
    
            goto L_8850685C;
    }
    // 0x88506834: nop

    // 0x88506838: lw          $t9, 0x34($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X34);
    // 0x8850683C: sll         $t6, $v0, 1
    ctx->r14 = S32(ctx->r2 << 1);
    // 0x88506840: addu        $t7, $t9, $t6
    ctx->r15 = ADD32(ctx->r25, ctx->r14);
    // 0x88506844: lhu         $t8, 0x0($t7)
    ctx->r24 = MEM_HU(ctx->r15, 0X0);
    // 0x88506848: andi        $t9, $t8, 0x4
    ctx->r25 = ctx->r24 & 0X4;
    // 0x8850684C: bne         $t9, $zero, L_8850685C
    if (ctx->r25 != 0) {
        // 0x88506850: nop
    
            goto L_8850685C;
    }
    // 0x88506850: nop

    // 0x88506854: b           L_8850687C
    // 0x88506858: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
        goto L_8850687C;
    // 0x88506858: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
L_8850685C:
    // 0x8850685C: bne         $a3, $zero, L_8850686C
    if (ctx->r7 != 0) {
        // 0x88506860: addiu       $a1, $a1, 0x1
        ctx->r5 = ADD32(ctx->r5, 0X1);
            goto L_8850686C;
    }
    // 0x88506860: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
    // 0x88506864: b           L_88506870
    // 0x88506868: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
        goto L_88506870;
    // 0x88506868: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
L_8850686C:
    // 0x8850686C: or          $v0, $a3, $zero
    ctx->r2 = ctx->r7 | 0;
L_88506870:
    // 0x88506870: slt         $at, $a1, $t0
    ctx->r1 = SIGNED(ctx->r5) < SIGNED(ctx->r8) ? 1 : 0;
    // 0x88506874: bne         $at, $zero, L_88506828
    if (ctx->r1 != 0) {
        // 0x88506878: addiu       $a3, $v0, -0x1
        ctx->r7 = ADD32(ctx->r2, -0X1);
            goto L_88506828;
    }
    // 0x88506878: addiu       $a3, $v0, -0x1
    ctx->r7 = ADD32(ctx->r2, -0X1);
L_8850687C:
    // 0x8850687C: beql        $t4, $zero, L_88506890
    if (ctx->r12 == 0) {
        // 0x88506880: addiu       $a0, $a0, 0x1
        ctx->r4 = ADD32(ctx->r4, 0X1);
            goto L_88506890;
    }
    goto skip_7;
    // 0x88506880: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
    skip_7:
    // 0x88506884: b           L_8850689C
    // 0x88506888: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
        goto L_8850689C;
    // 0x88506888: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    // 0x8850688C: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
L_88506890:
    // 0x88506890: bnel        $a0, $t3, L_885067F4
    if (ctx->r4 != ctx->r11) {
        // 0x88506894: or          $a1, $zero, $zero
        ctx->r5 = 0 | 0;
            goto L_885067F4;
    }
    goto skip_8;
    // 0x88506894: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    skip_8:
    // 0x88506898: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_8850689C:
    // 0x8850689C: lhu         $t6, 0x28($s0)
    ctx->r14 = MEM_HU(ctx->r16, 0X28);
    // 0x885068A0: lw          $a3, 0x50($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X50);
    // 0x885068A4: andi        $t7, $t6, 0x200
    ctx->r15 = ctx->r14 & 0X200;
    // 0x885068A8: beql        $t7, $zero, L_885068D4
    if (ctx->r15 == 0) {
        // 0x885068AC: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885068D4;
    }
    goto skip_9;
    // 0x885068AC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_9:
    // 0x885068B0: beql        $t4, $zero, L_885068C8
    if (ctx->r12 == 0) {
        // 0x885068B4: addiu       $t8, $zero, 0x8
        ctx->r24 = ADD32(0, 0X8);
            goto L_885068C8;
    }
    goto skip_10;
    // 0x885068B4: addiu       $t8, $zero, 0x8
    ctx->r24 = ADD32(0, 0X8);
    skip_10:
    // 0x885068B8: slt         $at, $t1, $ra
    ctx->r1 = SIGNED(ctx->r9) < SIGNED(ctx->r31) ? 1 : 0;
    // 0x885068BC: beql        $at, $zero, L_885068D4
    if (ctx->r1 == 0) {
        // 0x885068C0: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885068D4;
    }
    goto skip_11;
    // 0x885068C0: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_11:
    // 0x885068C4: addiu       $t8, $zero, 0x8
    ctx->r24 = ADD32(0, 0X8);
L_885068C8:
    // 0x885068C8: sw          $t8, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = ctx->r24;
    // 0x885068CC: or          $t4, $zero, $zero
    ctx->r12 = 0 | 0;
    // 0x885068D0: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_885068D4:
    // 0x885068D4: b           L_88506AFC
    // 0x885068D8: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
        goto L_88506AFC;
    // 0x885068D8: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
    // 0x885068DC: lw          $t9, 0x24($sp)
    ctx->r25 = MEM_W(ctx->r29, 0X24);
L_885068E0:
    // 0x885068E0: addiu       $at, $zero, 0x100
    ctx->r1 = ADD32(0, 0X100);
    // 0x885068E4: bnel        $t9, $at, L_885069EC
    if (ctx->r25 != ctx->r1) {
        // 0x885068E8: lw          $t8, 0x24($sp)
        ctx->r24 = MEM_W(ctx->r29, 0X24);
            goto L_885069EC;
    }
    goto skip_12;
    // 0x885068E8: lw          $t8, 0x24($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X24);
    skip_12:
    // 0x885068EC: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    // 0x885068F0: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x885068F4: or          $a3, $t5, $zero
    ctx->r7 = ctx->r13 | 0;
    // 0x885068F8: addiu       $a2, $t0, -0x1
    ctx->r6 = ADD32(ctx->r8, -0X1);
    // 0x885068FC: blezl       $a2, L_885069B0
    if (SIGNED(ctx->r6) <= 0) {
        // 0x88506900: lhu         $t9, 0x28($s0)
        ctx->r25 = MEM_HU(ctx->r16, 0X28);
            goto L_885069B0;
    }
    goto skip_13;
    // 0x88506900: lhu         $t9, 0x28($s0)
    ctx->r25 = MEM_HU(ctx->r16, 0X28);
    skip_13:
    // 0x88506904: lh          $t3, 0x4E($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X4E);
    // 0x88506908: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
L_8850690C:
    // 0x8850690C: bne         $a3, $a2, L_8850691C
    if (ctx->r7 != ctx->r6) {
        // 0x88506910: or          $t1, $t3, $zero
        ctx->r9 = ctx->r11 | 0;
            goto L_8850691C;
    }
    // 0x88506910: or          $t1, $t3, $zero
    ctx->r9 = ctx->r11 | 0;
    // 0x88506914: b           L_88506920
    // 0x88506918: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
        goto L_88506920;
    // 0x88506918: or          $a3, $zero, $zero
    ctx->r7 = 0 | 0;
L_8850691C:
    // 0x8850691C: addiu       $a3, $a3, 0x1
    ctx->r7 = ADD32(ctx->r7, 0X1);
L_88506920:
    // 0x88506920: blez        $t2, L_88506988
    if (SIGNED(ctx->r10) <= 0) {
        // 0x88506924: nop
    
            goto L_88506988;
    }
    // 0x88506924: nop

    // 0x88506928: lw          $t6, 0x2C($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X2C);
    // 0x8850692C: lw          $v1, 0x8($t6)
    ctx->r3 = MEM_W(ctx->r14, 0X8);
L_88506930:
    // 0x88506930: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506934: mflo        $t7
    ctx->r15 = lo;
    // 0x88506938: addu        $v0, $t7, $a3
    ctx->r2 = ADD32(ctx->r15, ctx->r7);
    // 0x8850693C: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    // 0x88506940: beq         $at, $zero, L_8850696C
    if (ctx->r1 == 0) {
        // 0x88506944: nop
    
            goto L_8850696C;
    }
    // 0x88506944: nop

    // 0x88506948: lw          $t8, 0x34($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X34);
    // 0x8850694C: sll         $t9, $v0, 1
    ctx->r25 = S32(ctx->r2 << 1);
    // 0x88506950: addu        $t6, $t8, $t9
    ctx->r14 = ADD32(ctx->r24, ctx->r25);
    // 0x88506954: lhu         $t7, 0x0($t6)
    ctx->r15 = MEM_HU(ctx->r14, 0X0);
    // 0x88506958: andi        $t8, $t7, 0x4
    ctx->r24 = ctx->r15 & 0X4;
    // 0x8850695C: bne         $t8, $zero, L_8850696C
    if (ctx->r24 != 0) {
        // 0x88506960: nop
    
            goto L_8850696C;
    }
    // 0x88506960: nop

    // 0x88506964: b           L_88506988
    // 0x88506968: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
        goto L_88506988;
    // 0x88506968: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
L_8850696C:
    // 0x8850696C: bne         $t1, $zero, L_8850697C
    if (ctx->r9 != 0) {
        // 0x88506970: addiu       $a0, $a0, 0x1
        ctx->r4 = ADD32(ctx->r4, 0X1);
            goto L_8850697C;
    }
    // 0x88506970: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
    // 0x88506974: b           L_88506980
    // 0x88506978: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
        goto L_88506980;
    // 0x88506978: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
L_8850697C:
    // 0x8850697C: or          $v0, $t1, $zero
    ctx->r2 = ctx->r9 | 0;
L_88506980:
    // 0x88506980: bne         $a0, $t2, L_88506930
    if (ctx->r4 != ctx->r10) {
        // 0x88506984: addiu       $t1, $v0, -0x1
        ctx->r9 = ADD32(ctx->r2, -0X1);
            goto L_88506930;
    }
    // 0x88506984: addiu       $t1, $v0, -0x1
    ctx->r9 = ADD32(ctx->r2, -0X1);
L_88506988:
    // 0x88506988: beql        $t4, $zero, L_8850699C
    if (ctx->r12 == 0) {
        // 0x8850698C: addiu       $a1, $a1, 0x1
        ctx->r5 = ADD32(ctx->r5, 0X1);
            goto L_8850699C;
    }
    goto skip_14;
    // 0x8850698C: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
    skip_14:
    // 0x88506990: b           L_885069AC
    // 0x88506994: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
        goto L_885069AC;
    // 0x88506994: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
    // 0x88506998: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
L_8850699C:
    // 0x8850699C: slt         $at, $a1, $a2
    ctx->r1 = SIGNED(ctx->r5) < SIGNED(ctx->r6) ? 1 : 0;
    // 0x885069A0: bnel        $at, $zero, L_8850690C
    if (ctx->r1 != 0) {
        // 0x885069A4: or          $a0, $zero, $zero
        ctx->r4 = 0 | 0;
            goto L_8850690C;
    }
    goto skip_15;
    // 0x885069A4: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    skip_15:
    // 0x885069A8: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
L_885069AC:
    // 0x885069AC: lhu         $t9, 0x28($s0)
    ctx->r25 = MEM_HU(ctx->r16, 0X28);
L_885069B0:
    // 0x885069B0: lw          $t1, 0x4C($sp)
    ctx->r9 = MEM_W(ctx->r29, 0X4C);
    // 0x885069B4: andi        $t6, $t9, 0x100
    ctx->r14 = ctx->r25 & 0X100;
    // 0x885069B8: beql        $t6, $zero, L_885069E0
    if (ctx->r14 == 0) {
        // 0x885069BC: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885069E0;
    }
    goto skip_16;
    // 0x885069BC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_16:
    // 0x885069C0: beq         $t4, $zero, L_885069D4
    if (ctx->r12 == 0) {
        // 0x885069C4: addiu       $t7, $zero, 0x8
        ctx->r15 = ADD32(0, 0X8);
            goto L_885069D4;
    }
    // 0x885069C4: addiu       $t7, $zero, 0x8
    ctx->r15 = ADD32(0, 0X8);
    // 0x885069C8: slt         $at, $a3, $t5
    ctx->r1 = SIGNED(ctx->r7) < SIGNED(ctx->r13) ? 1 : 0;
    // 0x885069CC: beql        $at, $zero, L_885069E0
    if (ctx->r1 == 0) {
        // 0x885069D0: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_885069E0;
    }
    goto skip_17;
    // 0x885069D0: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_17:
L_885069D4:
    // 0x885069D4: sw          $t7, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = ctx->r15;
    // 0x885069D8: or          $t4, $zero, $zero
    ctx->r12 = 0 | 0;
    // 0x885069DC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_885069E0:
    // 0x885069E0: b           L_88506AFC
    // 0x885069E4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
        goto L_88506AFC;
    // 0x885069E4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
    // 0x885069E8: lw          $t8, 0x24($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X24);
L_885069EC:
    // 0x885069EC: addiu       $at, $zero, 0x200
    ctx->r1 = ADD32(0, 0X200);
    // 0x885069F0: bnel        $t8, $at, L_88506B00
    if (ctx->r24 != ctx->r1) {
        // 0x885069F4: lw          $a3, 0x50($sp)
        ctx->r7 = MEM_W(ctx->r29, 0X50);
            goto L_88506B00;
    }
    goto skip_18;
    // 0x885069F4: lw          $a3, 0x50($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X50);
    skip_18:
    // 0x885069F8: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    // 0x885069FC: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
    // 0x88506A00: or          $a3, $t5, $zero
    ctx->r7 = ctx->r13 | 0;
    // 0x88506A04: addiu       $a2, $t0, -0x1
    ctx->r6 = ADD32(ctx->r8, -0X1);
    // 0x88506A08: blezl       $a2, L_88506ABC
    if (SIGNED(ctx->r6) <= 0) {
        // 0x88506A0C: sw          $a3, 0x50($sp)
        MEM_W(0X50, ctx->r29) = ctx->r7;
            goto L_88506ABC;
    }
    goto skip_19;
    // 0x88506A0C: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    skip_19:
    // 0x88506A10: lh          $t3, 0x4E($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X4E);
    // 0x88506A14: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
L_88506A18:
    // 0x88506A18: bne         $a3, $zero, L_88506A28
    if (ctx->r7 != 0) {
        // 0x88506A1C: or          $t1, $t3, $zero
        ctx->r9 = ctx->r11 | 0;
            goto L_88506A28;
    }
    // 0x88506A1C: or          $t1, $t3, $zero
    ctx->r9 = ctx->r11 | 0;
    // 0x88506A20: b           L_88506A2C
    // 0x88506A24: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
        goto L_88506A2C;
    // 0x88506A24: or          $v0, $t0, $zero
    ctx->r2 = ctx->r8 | 0;
L_88506A28:
    // 0x88506A28: or          $v0, $a3, $zero
    ctx->r2 = ctx->r7 | 0;
L_88506A2C:
    // 0x88506A2C: blez        $t2, L_88506A94
    if (SIGNED(ctx->r10) <= 0) {
        // 0x88506A30: addiu       $a3, $v0, -0x1
        ctx->r7 = ADD32(ctx->r2, -0X1);
            goto L_88506A94;
    }
    // 0x88506A30: addiu       $a3, $v0, -0x1
    ctx->r7 = ADD32(ctx->r2, -0X1);
    // 0x88506A34: lw          $t9, 0x2C($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X2C);
    // 0x88506A38: lw          $v1, 0x8($t9)
    ctx->r3 = MEM_W(ctx->r25, 0X8);
L_88506A3C:
    // 0x88506A3C: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506A40: mflo        $t6
    ctx->r14 = lo;
    // 0x88506A44: addu        $v0, $t6, $a3
    ctx->r2 = ADD32(ctx->r14, ctx->r7);
    // 0x88506A48: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    // 0x88506A4C: beq         $at, $zero, L_88506A78
    if (ctx->r1 == 0) {
        // 0x88506A50: nop
    
            goto L_88506A78;
    }
    // 0x88506A50: nop

    // 0x88506A54: lw          $t7, 0x34($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X34);
    // 0x88506A58: sll         $t8, $v0, 1
    ctx->r24 = S32(ctx->r2 << 1);
    // 0x88506A5C: addu        $t9, $t7, $t8
    ctx->r25 = ADD32(ctx->r15, ctx->r24);
    // 0x88506A60: lhu         $t6, 0x0($t9)
    ctx->r14 = MEM_HU(ctx->r25, 0X0);
    // 0x88506A64: andi        $t7, $t6, 0x4
    ctx->r15 = ctx->r14 & 0X4;
    // 0x88506A68: bne         $t7, $zero, L_88506A78
    if (ctx->r15 != 0) {
        // 0x88506A6C: nop
    
            goto L_88506A78;
    }
    // 0x88506A6C: nop

    // 0x88506A70: b           L_88506A94
    // 0x88506A74: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
        goto L_88506A94;
    // 0x88506A74: addiu       $t4, $zero, 0x1
    ctx->r12 = ADD32(0, 0X1);
L_88506A78:
    // 0x88506A78: bne         $t1, $zero, L_88506A88
    if (ctx->r9 != 0) {
        // 0x88506A7C: addiu       $a0, $a0, 0x1
        ctx->r4 = ADD32(ctx->r4, 0X1);
            goto L_88506A88;
    }
    // 0x88506A7C: addiu       $a0, $a0, 0x1
    ctx->r4 = ADD32(ctx->r4, 0X1);
    // 0x88506A80: b           L_88506A8C
    // 0x88506A84: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
        goto L_88506A8C;
    // 0x88506A84: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
L_88506A88:
    // 0x88506A88: or          $v0, $t1, $zero
    ctx->r2 = ctx->r9 | 0;
L_88506A8C:
    // 0x88506A8C: bne         $a0, $t2, L_88506A3C
    if (ctx->r4 != ctx->r10) {
        // 0x88506A90: addiu       $t1, $v0, -0x1
        ctx->r9 = ADD32(ctx->r2, -0X1);
            goto L_88506A3C;
    }
    // 0x88506A90: addiu       $t1, $v0, -0x1
    ctx->r9 = ADD32(ctx->r2, -0X1);
L_88506A94:
    // 0x88506A94: beql        $t4, $zero, L_88506AA8
    if (ctx->r12 == 0) {
        // 0x88506A98: addiu       $a1, $a1, 0x1
        ctx->r5 = ADD32(ctx->r5, 0X1);
            goto L_88506AA8;
    }
    goto skip_20;
    // 0x88506A98: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
    skip_20:
    // 0x88506A9C: b           L_88506AB8
    // 0x88506AA0: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
        goto L_88506AB8;
    // 0x88506AA0: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
    // 0x88506AA4: addiu       $a1, $a1, 0x1
    ctx->r5 = ADD32(ctx->r5, 0X1);
L_88506AA8:
    // 0x88506AA8: slt         $at, $a1, $a2
    ctx->r1 = SIGNED(ctx->r5) < SIGNED(ctx->r6) ? 1 : 0;
    // 0x88506AAC: bnel        $at, $zero, L_88506A18
    if (ctx->r1 != 0) {
        // 0x88506AB0: or          $a0, $zero, $zero
        ctx->r4 = 0 | 0;
            goto L_88506A18;
    }
    goto skip_21;
    // 0x88506AB0: or          $a0, $zero, $zero
    ctx->r4 = 0 | 0;
    skip_21:
    // 0x88506AB4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
L_88506AB8:
    // 0x88506AB8: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
L_88506ABC:
    // 0x88506ABC: lhu         $t8, 0x28($s0)
    ctx->r24 = MEM_HU(ctx->r16, 0X28);
    // 0x88506AC0: lw          $t1, 0x4C($sp)
    ctx->r9 = MEM_W(ctx->r29, 0X4C);
    // 0x88506AC4: andi        $t9, $t8, 0x100
    ctx->r25 = ctx->r24 & 0X100;
    // 0x88506AC8: beql        $t9, $zero, L_88506B00
    if (ctx->r25 == 0) {
        // 0x88506ACC: lw          $a3, 0x50($sp)
        ctx->r7 = MEM_W(ctx->r29, 0X50);
            goto L_88506B00;
    }
    goto skip_22;
    // 0x88506ACC: lw          $a3, 0x50($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X50);
    skip_22:
    // 0x88506AD0: beql        $t4, $zero, L_88506AEC
    if (ctx->r12 == 0) {
        // 0x88506AD4: addiu       $t6, $zero, 0x8
        ctx->r14 = ADD32(0, 0X8);
            goto L_88506AEC;
    }
    goto skip_23;
    // 0x88506AD4: addiu       $t6, $zero, 0x8
    ctx->r14 = ADD32(0, 0X8);
    skip_23:
    // 0x88506AD8: slt         $at, $t5, $a3
    ctx->r1 = SIGNED(ctx->r13) < SIGNED(ctx->r7) ? 1 : 0;
    // 0x88506ADC: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    // 0x88506AE0: beq         $at, $zero, L_88506AFC
    if (ctx->r1 == 0) {
        // 0x88506AE4: sw          $t1, 0x4C($sp)
        MEM_W(0X4C, ctx->r29) = ctx->r9;
            goto L_88506AFC;
    }
    // 0x88506AE4: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
    // 0x88506AE8: addiu       $t6, $zero, 0x8
    ctx->r14 = ADD32(0, 0X8);
L_88506AEC:
    // 0x88506AEC: sw          $t6, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = ctx->r14;
    // 0x88506AF0: or          $t4, $zero, $zero
    ctx->r12 = 0 | 0;
    // 0x88506AF4: sw          $a3, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r7;
    // 0x88506AF8: sw          $t1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r9;
L_88506AFC:
    // 0x88506AFC: lw          $a3, 0x50($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X50);
L_88506B00:
    // 0x88506B00: beq         $t4, $zero, L_88506BE4
    if (ctx->r12 == 0) {
        // 0x88506B04: lw          $t1, 0x4C($sp)
        ctx->r9 = MEM_W(ctx->r29, 0X4C);
            goto L_88506BE4;
    }
    // 0x88506B04: lw          $t1, 0x4C($sp)
    ctx->r9 = MEM_W(ctx->r29, 0X4C);
    // 0x88506B08: lh          $t0, 0x48($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X48);
    // 0x88506B0C: lh          $t9, 0x3C($s0)
    ctx->r25 = MEM_H(ctx->r16, 0X3C);
    // 0x88506B10: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506B14: mflo        $t7
    ctx->r15 = lo;
    // 0x88506B18: addu        $v0, $t7, $a3
    ctx->r2 = ADD32(ctx->r15, ctx->r7);
    // 0x88506B1C: lh          $t7, 0x50($s0)
    ctx->r15 = MEM_H(ctx->r16, 0X50);
    // 0x88506B20: div         $zero, $v0, $t0
    lo = S32(S64(S32(ctx->r2)) / S64(S32(ctx->r8))); hi = S32(S64(S32(ctx->r2)) % S64(S32(ctx->r8)));
    // 0x88506B24: mfhi        $t8
    ctx->r24 = hi;
    // 0x88506B28: sw          $v0, 0x38($s0)
    MEM_W(0X38, ctx->r16) = ctx->r2;
    // 0x88506B2C: bne         $t0, $zero, L_88506B38
    if (ctx->r8 != 0) {
        // 0x88506B30: nop
    
            goto L_88506B38;
    }
    // 0x88506B30: nop

    // 0x88506B34: break       7
    do_break(2286971700);
L_88506B38:
    // 0x88506B38: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x88506B3C: bne         $t0, $at, L_88506B50
    if (ctx->r8 != ctx->r1) {
        // 0x88506B40: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_88506B50;
    }
    // 0x88506B40: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x88506B44: bne         $v0, $at, L_88506B50
    if (ctx->r2 != ctx->r1) {
        // 0x88506B48: nop
    
            goto L_88506B50;
    }
    // 0x88506B48: nop

    // 0x88506B4C: break       6
    do_break(2286971724);
L_88506B50:
    // 0x88506B50: multu       $t8, $t9
    result = U64(U32(ctx->r24)) * U64(U32(ctx->r25)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506B54: lw          $t9, 0x44($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X44);
    // 0x88506B58: mflo        $t6
    ctx->r14 = lo;
    // 0x88506B5C: addu        $t8, $t6, $t7
    ctx->r24 = ADD32(ctx->r14, ctx->r15);
    // 0x88506B60: sh          $t8, 0x10($t9)
    MEM_H(0X10, ctx->r25) = ctx->r24;
    // 0x88506B64: lh          $t7, 0x48($s0)
    ctx->r15 = MEM_H(ctx->r16, 0X48);
    // 0x88506B68: lw          $t6, 0x38($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X38);
    // 0x88506B6C: lh          $t9, 0x3E($s0)
    ctx->r25 = MEM_H(ctx->r16, 0X3E);
    // 0x88506B70: div         $zero, $t6, $t7
    lo = S32(S64(S32(ctx->r14)) / S64(S32(ctx->r15))); hi = S32(S64(S32(ctx->r14)) % S64(S32(ctx->r15)));
    // 0x88506B74: mflo        $t8
    ctx->r24 = lo;
    // 0x88506B78: bne         $t7, $zero, L_88506B84
    if (ctx->r15 != 0) {
        // 0x88506B7C: nop
    
            goto L_88506B84;
    }
    // 0x88506B7C: nop

    // 0x88506B80: break       7
    do_break(2286971776);
L_88506B84:
    // 0x88506B84: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x88506B88: bne         $t7, $at, L_88506B9C
    if (ctx->r15 != ctx->r1) {
        // 0x88506B8C: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_88506B9C;
    }
    // 0x88506B8C: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x88506B90: bne         $t6, $at, L_88506B9C
    if (ctx->r14 != ctx->r1) {
        // 0x88506B94: nop
    
            goto L_88506B9C;
    }
    // 0x88506B94: nop

    // 0x88506B98: break       6
    do_break(2286971800);
L_88506B9C:
    // 0x88506B9C: multu       $t8, $t9
    result = U64(U32(ctx->r24)) * U64(U32(ctx->r25)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x88506BA0: lh          $t7, 0x52($s0)
    ctx->r15 = MEM_H(ctx->r16, 0X52);
    // 0x88506BA4: lw          $t9, 0x44($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X44);
    // 0x88506BA8: addiu       $at, $zero, 0x800
    ctx->r1 = ADD32(0, 0X800);
    // 0x88506BAC: mflo        $t6
    ctx->r14 = lo;
    // 0x88506BB0: addu        $t8, $t6, $t7
    ctx->r24 = ADD32(ctx->r14, ctx->r15);
    // 0x88506BB4: sh          $t8, 0x12($t9)
    MEM_H(0X12, ctx->r25) = ctx->r24;
    // 0x88506BB8: lw          $t6, 0x24($sp)
    ctx->r14 = MEM_W(ctx->r29, 0X24);
    // 0x88506BBC: lui         $t7, 0x8000
    ctx->r15 = S32(0X8000 << 16);
    // 0x88506BC0: ori         $t7, $t7, 0x9
    ctx->r15 = ctx->r15 | 0X9;
    // 0x88506BC4: beq         $t6, $at, L_88506BD4
    if (ctx->r14 == ctx->r1) {
        // 0x88506BC8: addiu       $at, $zero, 0x400
        ctx->r1 = ADD32(0, 0X400);
            goto L_88506BD4;
    }
    // 0x88506BC8: addiu       $at, $zero, 0x400
    ctx->r1 = ADD32(0, 0X400);
    // 0x88506BCC: bnel        $t6, $at, L_88506BE0
    if (ctx->r14 != ctx->r1) {
        // 0x88506BD0: sh          $a3, 0x4C($s0)
        MEM_H(0X4C, ctx->r16) = ctx->r7;
            goto L_88506BE0;
    }
    goto skip_24;
    // 0x88506BD0: sh          $a3, 0x4C($s0)
    MEM_H(0X4C, ctx->r16) = ctx->r7;
    skip_24:
L_88506BD4:
    // 0x88506BD4: b           L_88506BE0
    // 0x88506BD8: sh          $t1, 0x4E($s0)
    MEM_H(0X4E, ctx->r16) = ctx->r9;
        goto L_88506BE0;
    // 0x88506BD8: sh          $t1, 0x4E($s0)
    MEM_H(0X4E, ctx->r16) = ctx->r9;
    // 0x88506BDC: sh          $a3, 0x4C($s0)
    MEM_H(0X4C, ctx->r16) = ctx->r7;
L_88506BE0:
    // 0x88506BE0: sw          $t7, 0x5C($sp)
    MEM_W(0X5C, ctx->r29) = ctx->r15;
L_88506BE4:
    // 0x88506BE4: lw          $v0, 0x5C($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X5C);
L_88506BE8:
    // 0x88506BE8: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x88506BEC: lw          $s0, 0x18($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X18);
    // 0x88506BF0: addiu       $sp, $sp, 0x60
    ctx->r29 = ADD32(ctx->r29, 0X60);
    // 0x88506BF4: jr          $ra
    // 0x88506BF8: nop

    return;
    // 0x88506BF8: nop

;}
RECOMP_FUNC void func_82D018AC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82D018AC: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x82D018B0: addiu       $at, $zero, 0x5
    ctx->r1 = ADD32(0, 0X5);
    // 0x82D018B4: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x82D018B8: bne         $a0, $at, L_82D01938
    if (ctx->r4 != ctx->r1) {
        // 0x82D018BC: sw          $a1, 0x1C($sp)
        MEM_W(0X1C, ctx->r29) = ctx->r5;
            goto L_82D01938;
    }
    // 0x82D018BC: sw          $a1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r5;
    // 0x82D018C0: lui         $v1, 0x800A
    ctx->r3 = S32(0X800A << 16);
    // 0x82D018C4: addiu       $v1, $v1, 0x7420
    ctx->r3 = ADD32(ctx->r3, 0X7420);
    // 0x82D018C8: lw          $v0, 0x0($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X0);
    // 0x82D018CC: lui         $t7, 0xE700
    ctx->r15 = S32(0XE700 << 16);
    // 0x82D018D0: lui         $t9, 0xDB06
    ctx->r25 = S32(0XDB06 << 16);
    // 0x82D018D4: addiu       $t6, $v0, 0x8
    ctx->r14 = ADD32(ctx->r2, 0X8);
    // 0x82D018D8: sw          $t6, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r14;
    // 0x82D018DC: sw          $zero, 0x4($v0)
    MEM_W(0X4, ctx->r2) = 0;
    // 0x82D018E0: sw          $t7, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r15;
    // 0x82D018E4: lw          $v0, 0x0($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X0);
    // 0x82D018E8: ori         $t9, $t9, 0x3C
    ctx->r25 = ctx->r25 | 0X3C;
    // 0x82D018EC: lui         $t0, 0x82D1
    ctx->r8 = S32(RELOC_HI16(239, 0XABCC) << 16);
    // 0x82D018F0: addiu       $t8, $v0, 0x8
    ctx->r24 = ADD32(ctx->r2, 0X8);
    // 0x82D018F4: sw          $t8, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r24;
    // 0x82D018F8: sw          $t9, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r25;
    // 0x82D018FC: lw          $t0, -0x5434($t0)
    ctx->r8 = MEM_W(ctx->r8, (int16_t)RELOC_LO16(239, 0XABCC));
    // 0x82D01900: lui         $at, 0x1FFF
    ctx->r1 = S32(0X1FFF << 16);
    // 0x82D01904: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x82D01908: lw          $t1, 0x8($t0)
    ctx->r9 = MEM_W(ctx->r8, 0X8);
    // 0x82D0190C: lui         $t5, 0x82D1
    ctx->r13 = S32(RELOC_HI16(239, 0X8740) << 16);
    // 0x82D01910: addiu       $t5, $t5, -0x78C0
    ctx->r13 = ADD32(ctx->r13, (int16_t)RELOC_LO16(239, 0X8740));
    // 0x82D01914: and         $t2, $t1, $at
    ctx->r10 = ctx->r9 & ctx->r1;
    // 0x82D01918: sw          $t2, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r10;
    // 0x82D0191C: lw          $v0, 0x0($v1)
    ctx->r2 = MEM_W(ctx->r3, 0X0);
    // 0x82D01920: lui         $t4, 0xDE00
    ctx->r12 = S32(0XDE00 << 16);
    // 0x82D01924: addiu       $t3, $v0, 0x8
    ctx->r11 = ADD32(ctx->r2, 0X8);
    // 0x82D01928: sw          $t3, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r11;
    // 0x82D0192C: sw          $t5, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r13;
    // 0x82D01930: jal         0x80015684
    // 0x82D01934: sw          $t4, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r12;
    func_80015684(rdram, ctx);
        goto after_0;
    // 0x82D01934: sw          $t4, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r12;
    after_0:
L_82D01938:
    // 0x82D01938: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x82D0193C: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x82D01940: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x82D01944: jr          $ra
    // 0x82D01948: nop

    return;
    // 0x82D01948: nop

;}
RECOMP_FUNC void proutSprintf(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8005E020: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x8005E024: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x8005E028: jal         0x8005E250
    // 0x8005E02C: sw          $a2, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r6;
    memcpy_recomp(rdram, ctx);
        goto after_0;
    // 0x8005E02C: sw          $a2, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r6;
    after_0:
    // 0x8005E030: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x8005E034: lw          $t6, 0x20($sp)
    ctx->r14 = MEM_W(ctx->r29, 0X20);
    // 0x8005E038: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x8005E03C: jr          $ra
    // 0x8005E040: addu        $v0, $v0, $t6
    ctx->r2 = ADD32(ctx->r2, ctx->r14);
    return;
    // 0x8005E040: addu        $v0, $v0, $t6
    ctx->r2 = ADD32(ctx->r2, ctx->r14);
;}
RECOMP_FUNC void env_static_80061054(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80061054: addiu       $sp, $sp, -0xB8
    ctx->r29 = ADD32(ctx->r29, -0XB8);
    // 0x80061058: lw          $a0, 0xC8($sp)
    ctx->r4 = MEM_W(ctx->r29, 0XC8);
    // 0x8006105C: sdc1        $f20, 0x10($sp)
    CHECK_FR(ctx, 20);
    SD(ctx->f20.u64, 0X10, ctx->r29);
    // 0x80061060: mov.d       $f20, $f12
    CHECK_FR(ctx, 20);
    CHECK_FR(ctx, 12);
    ctx->f20.d = ctx->f12.d;
    // 0x80061064: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x80061068: bne         $a0, $zero, L_8006109C
    if (ctx->r4 != 0) {
        // 0x8006106C: sdc1        $f22, 0x18($sp)
        CHECK_FR(ctx, 22);
    SD(ctx->f22.u64, 0X18, ctx->r29);
            goto L_8006109C;
    }
    // 0x8006106C: sdc1        $f22, 0x18($sp)
    CHECK_FR(ctx, 22);
    SD(ctx->f22.u64, 0X18, ctx->r29);
    // 0x80061070: c.le.d      $f12, $f14
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 14);
    c1cs = ctx->f12.d <= ctx->f14.d;
    // 0x80061074: ori         $t6, $zero, 0xFFFF
    ctx->r14 = 0 | 0XFFFF;
    // 0x80061078: lw          $t7, 0xCC($sp)
    ctx->r15 = MEM_W(ctx->r29, 0XCC);
    // 0x8006107C: lw          $t8, 0xCC($sp)
    ctx->r24 = MEM_W(ctx->r29, 0XCC);
    // 0x80061080: bc1f        L_80061094
    if (!c1cs) {
        // 0x80061084: or          $v0, $zero, $zero
        ctx->r2 = 0 | 0;
            goto L_80061094;
    }
    // 0x80061084: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x80061088: sh          $t6, 0x0($t7)
    MEM_H(0X0, ctx->r15) = ctx->r14;
    // 0x8006108C: b           L_80061224
    // 0x80061090: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
        goto L_80061224;
    // 0x80061090: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
L_80061094:
    // 0x80061094: b           L_80061224
    // 0x80061098: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
        goto L_80061224;
    // 0x80061098: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
L_8006109C:
    // 0x8006109C: lui         $at, 0x3FF0
    ctx->r1 = S32(0X3FF0 << 16);
    // 0x800610A0: mtc1        $at, $f23
    ctx->f_odd[(23 - 1) * 2] = ctx->r1;
    // 0x800610A4: mtc1        $zero, $f22
    ctx->f22.u32l = 0;
    // 0x800610A8: lui         $t0, 0x8008
    ctx->r8 = S32(0X8008 << 16);
    // 0x800610AC: mtc1        $zero, $f5
    ctx->f_odd[(5 - 1) * 2] = 0;
    // 0x800610B0: c.lt.d      $f14, $f22
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 22);
    c1cs = ctx->f14.d < ctx->f22.d;
    // 0x800610B4: mtc1        $zero, $f4
    ctx->f4.u32l = 0;
    // 0x800610B8: addiu       $t0, $t0, -0x53B0
    ctx->r8 = ADD32(ctx->r8, -0X53B0);
    // 0x800610BC: addiu       $t2, $t0, 0x3C
    ctx->r10 = ADD32(ctx->r8, 0X3C);
    // 0x800610C0: bc1f        L_800610CC
    if (!c1cs) {
        // 0x800610C4: addiu       $t9, $sp, 0x38
        ctx->r25 = ADD32(ctx->r29, 0X38);
            goto L_800610CC;
    }
    // 0x800610C4: addiu       $t9, $sp, 0x38
    ctx->r25 = ADD32(ctx->r29, 0X38);
    // 0x800610C8: mov.d       $f14, $f22
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 22);
    ctx->f14.d = ctx->f22.d;
L_800610CC:
    // 0x800610CC: c.le.d      $f20, $f4
    CHECK_FR(ctx, 20);
    CHECK_FR(ctx, 4);
    c1cs = ctx->f20.d <= ctx->f4.d;
    // 0x800610D0: mtc1        $a0, $f6
    ctx->f6.u32l = ctx->r4;
    // 0x800610D4: lui         $at, 0x3FF0
    ctx->r1 = S32(0X3FF0 << 16);
    // 0x800610D8: bc1f        L_800610EC
    if (!c1cs) {
        // 0x800610DC: cvt.d.w     $f8, $f6
        CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.d = CVT_D_W(ctx->f6.u32l);
            goto L_800610EC;
    }
    // 0x800610DC: cvt.d.w     $f8, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.d = CVT_D_W(ctx->f6.u32l);
    // 0x800610E0: mtc1        $at, $f21
    ctx->f_odd[(21 - 1) * 2] = ctx->r1;
    // 0x800610E4: mtc1        $zero, $f20
    ctx->f20.u32l = 0;
    // 0x800610E8: nop

L_800610EC:
    // 0x800610EC: lw          $at, 0x0($t0)
    ctx->r1 = MEM_W(ctx->r8, 0X0);
    // 0x800610F0: addiu       $t0, $t0, 0xC
    ctx->r8 = ADD32(ctx->r8, 0XC);
    // 0x800610F4: addiu       $t9, $t9, 0xC
    ctx->r25 = ADD32(ctx->r25, 0XC);
    // 0x800610F8: sw          $at, -0xC($t9)
    MEM_W(-0XC, ctx->r25) = ctx->r1;
    // 0x800610FC: lw          $at, -0x8($t0)
    ctx->r1 = MEM_W(ctx->r8, -0X8);
    // 0x80061100: sw          $at, -0x8($t9)
    MEM_W(-0X8, ctx->r25) = ctx->r1;
    // 0x80061104: lw          $at, -0x4($t0)
    ctx->r1 = MEM_W(ctx->r8, -0X4);
    // 0x80061108: bne         $t0, $t2, L_800610EC
    if (ctx->r8 != ctx->r10) {
        // 0x8006110C: sw          $at, -0x4($t9)
        MEM_W(-0X4, ctx->r25) = ctx->r1;
            goto L_800610EC;
    }
    // 0x8006110C: sw          $at, -0x4($t9)
    MEM_W(-0X4, ctx->r25) = ctx->r1;
    // 0x80061110: lw          $at, 0x0($t0)
    ctx->r1 = MEM_W(ctx->r8, 0X0);
    // 0x80061114: div.d       $f12, $f22, $f8
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 22);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f22.d); NAN_CHECK(ctx->f8.d); 
    ctx->f12.d = DIV_D(ctx->f22.d, ctx->f8.d);
    // 0x80061118: addiu       $a2, $zero, 0x1E
    ctx->r6 = ADD32(0, 0X1E);
    // 0x8006111C: sw          $at, 0x0($t9)
    MEM_W(0X0, ctx->r25) = ctx->r1;
    // 0x80061120: jal         0x8006102C
    // 0x80061124: sdc1        $f14, 0xC0($sp)
    CHECK_FR(ctx, 14);
    SD(ctx->f14.u64, 0XC0, ctx->r29);
    _ldexpf(rdram, ctx);
        goto after_0;
    // 0x80061124: sdc1        $f14, 0xC0($sp)
    CHECK_FR(ctx, 14);
    SD(ctx->f14.u64, 0XC0, ctx->r29);
    after_0:
    // 0x80061128: trunc.w.d   $f10, $f0
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 0);
    ctx->f10.u32l = TRUNC_W_D(ctx->f0.d);
    // 0x8006112C: ldc1        $f14, 0xC0($sp)
    CHECK_FR(ctx, 14);
    ctx->f14.u64 = LD(ctx->r29, 0XC0);
    // 0x80061130: addiu       $a2, $sp, 0x80
    ctx->r6 = ADD32(ctx->r29, 0X80);
    // 0x80061134: mfc1        $v0, $f10
    ctx->r2 = (int32_t)ctx->f10.u32l;
    // 0x80061138: div.d       $f12, $f14, $f20
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 20);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f20.d); 
    ctx->f12.d = DIV_D(ctx->f14.d, ctx->f20.d);
    // 0x8006113C: jal         0x80060F40
    // 0x80061140: sw          $v0, 0x84($sp)
    MEM_W(0X84, ctx->r29) = ctx->r2;
    _frexpf(rdram, ctx);
        goto after_1;
    // 0x80061140: sw          $v0, 0x84($sp)
    MEM_W(0X84, ctx->r29) = ctx->r2;
    after_1:
    // 0x80061144: mov.d       $f12, $f0
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 0);
    ctx->f12.d = ctx->f0.d;
    // 0x80061148: jal         0x8006102C
    // 0x8006114C: addiu       $a2, $zero, 0x4
    ctx->r6 = ADD32(0, 0X4);
    _ldexpf(rdram, ctx);
        goto after_2;
    // 0x8006114C: addiu       $a2, $zero, 0x4
    ctx->r6 = ADD32(0, 0X4);
    after_2:
    // 0x80061150: trunc.w.d   $f18, $f0
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 0);
    ctx->f18.u32l = TRUNC_W_D(ctx->f0.d);
    // 0x80061154: lw          $t8, 0x80($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X80);
    // 0x80061158: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x8006115C: mtc1        $zero, $f12
    ctx->f12.u32l = 0;
    // 0x80061160: mfc1        $t5, $f18
    ctx->r13 = (int32_t)ctx->f18.u32l;
    // 0x80061164: mtc1        $t8, $f6
    ctx->f6.u32l = ctx->r24;
    // 0x80061168: ldc1        $f18, -0x1AD8($at)
    CHECK_FR(ctx, 18);
    ctx->f18.u64 = LD(ctx->r1, -0X1AD8);
    // 0x8006116C: sll         $t6, $t5, 3
    ctx->r14 = S32(ctx->r13 << 3);
    // 0x80061170: cvt.d.w     $f8, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    ctx->f8.d = CVT_D_W(ctx->f6.u32l);
    // 0x80061174: addu        $t7, $sp, $t6
    ctx->r15 = ADD32(ctx->r29, ctx->r14);
    // 0x80061178: ldc1        $f4, -0x8($t7)
    CHECK_FR(ctx, 4);
    ctx->f4.u64 = LD(ctx->r15, -0X8);
    // 0x8006117C: lui         $at, 0x3FF0
    ctx->r1 = S32(0X3FF0 << 16);
    // 0x80061180: mtc1        $at, $f13
    ctx->f_odd[(13 - 1) * 2] = ctx->r1;
    // 0x80061184: add.d       $f10, $f4, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f4.d); NAN_CHECK(ctx->f8.d); 
    ctx->f10.d = ctx->f4.d + ctx->f8.d;
    // 0x80061188: addiu       $a2, $zero, 0x1E
    ctx->r6 = ADD32(0, 0X1E);
    // 0x8006118C: mul.d       $f14, $f10, $f18
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f10.d); NAN_CHECK(ctx->f18.d); 
    ctx->f14.d = MUL_D(ctx->f10.d, ctx->f18.d);
    // 0x80061190: jal         0x8006102C
    // 0x80061194: sdc1        $f14, 0xA0($sp)
    CHECK_FR(ctx, 14);
    SD(ctx->f14.u64, 0XA0, ctx->r29);
    _ldexpf(rdram, ctx);
        goto after_3;
    // 0x80061194: sdc1        $f14, 0xA0($sp)
    CHECK_FR(ctx, 14);
    SD(ctx->f14.u64, 0XA0, ctx->r29);
    after_3:
    // 0x80061198: ldc1        $f14, 0xA0($sp)
    CHECK_FR(ctx, 14);
    ctx->f14.u64 = LD(ctx->r29, 0XA0);
    // 0x8006119C: lw          $v0, 0x84($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X84);
    // 0x800611A0: mov.d       $f12, $f22
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 22);
    ctx->f12.d = ctx->f22.d;
    // 0x800611A4: div.d       $f14, $f14, $f0
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f0.d); 
    ctx->f14.d = DIV_D(ctx->f14.d, ctx->f0.d);
    // 0x800611A8: beq         $v0, $zero, L_800611D0
    if (ctx->r2 == 0) {
        // 0x800611AC: add.d       $f2, $f22, $f14
        CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 22);
    CHECK_FR(ctx, 14);
    NAN_CHECK(ctx->f22.d); NAN_CHECK(ctx->f14.d); 
    ctx->f2.d = ctx->f22.d + ctx->f14.d;
            goto L_800611D0;
    }
    // 0x800611AC: add.d       $f2, $f22, $f14
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 22);
    CHECK_FR(ctx, 14);
    NAN_CHECK(ctx->f22.d); NAN_CHECK(ctx->f14.d); 
    ctx->f2.d = ctx->f22.d + ctx->f14.d;
L_800611B0:
    // 0x800611B0: andi        $t1, $v0, 0x1
    ctx->r9 = ctx->r2 & 0X1;
    // 0x800611B4: beq         $t1, $zero, L_800611C4
    if (ctx->r9 == 0) {
        // 0x800611B8: sra         $t2, $v0, 1
        ctx->r10 = S32(SIGNED(ctx->r2) >> 1);
            goto L_800611C4;
    }
    // 0x800611B8: sra         $t2, $v0, 1
    ctx->r10 = S32(SIGNED(ctx->r2) >> 1);
    // 0x800611BC: mul.d       $f12, $f12, $f2
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f12.d); NAN_CHECK(ctx->f2.d); 
    ctx->f12.d = MUL_D(ctx->f12.d, ctx->f2.d);
    // 0x800611C0: nop

L_800611C4:
    // 0x800611C4: mul.d       $f2, $f2, $f2
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f2.d); NAN_CHECK(ctx->f2.d); 
    ctx->f2.d = MUL_D(ctx->f2.d, ctx->f2.d);
    // 0x800611C8: bne         $t2, $zero, L_800611B0
    if (ctx->r10 != 0) {
        // 0x800611CC: or          $v0, $t2, $zero
        ctx->r2 = ctx->r10 | 0;
            goto L_800611B0;
    }
    // 0x800611CC: or          $v0, $t2, $zero
    ctx->r2 = ctx->r10 | 0;
L_800611D0:
    // 0x800611D0: mul.d       $f0, $f12, $f12
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f12.d); NAN_CHECK(ctx->f12.d); 
    ctx->f0.d = MUL_D(ctx->f12.d, ctx->f12.d);
    // 0x800611D4: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x800611D8: lw          $t6, 0xCC($sp)
    ctx->r14 = MEM_W(ctx->r29, 0XCC);
    // 0x800611DC: mul.d       $f2, $f0, $f0
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f0.d); NAN_CHECK(ctx->f0.d); 
    ctx->f2.d = MUL_D(ctx->f0.d, ctx->f0.d);
    // 0x800611E0: nop

    // 0x800611E4: mul.d       $f12, $f2, $f2
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f2.d); NAN_CHECK(ctx->f2.d); 
    ctx->f12.d = MUL_D(ctx->f2.d, ctx->f2.d);
    // 0x800611E8: trunc.w.d   $f6, $f12
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 12);
    ctx->f6.u32l = TRUNC_W_D(ctx->f12.d);
    // 0x800611EC: mfc1        $v1, $f6
    ctx->r3 = (int32_t)ctx->f6.u32l;
    // 0x800611F0: ldc1        $f6, -0x1AD0($at)
    CHECK_FR(ctx, 6);
    ctx->f6.u64 = LD(ctx->r1, -0X1AD0);
    // 0x800611F4: sll         $t9, $v1, 16
    ctx->r25 = S32(ctx->r3 << 16);
    // 0x800611F8: sra         $v0, $t9, 16
    ctx->r2 = S32(SIGNED(ctx->r25) >> 16);
    // 0x800611FC: mtc1        $v0, $f4
    ctx->f4.u32l = ctx->r2;
    // 0x80061200: nop

    // 0x80061204: cvt.s.w     $f8, $f4
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 4);
    ctx->f8.fl = CVT_S_W(ctx->f4.u32l);
    // 0x80061208: cvt.d.s     $f10, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f8.fl); 
    ctx->f10.d = CVT_D_S(ctx->f8.fl);
    // 0x8006120C: sub.d       $f18, $f12, $f10
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f12.d); NAN_CHECK(ctx->f10.d); 
    ctx->f18.d = ctx->f12.d - ctx->f10.d;
    // 0x80061210: mul.d       $f4, $f18, $f6
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f6.d); 
    ctx->f4.d = MUL_D(ctx->f18.d, ctx->f6.d);
    // 0x80061214: trunc.w.d   $f8, $f4
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 4);
    ctx->f8.u32l = TRUNC_W_D(ctx->f4.d);
    // 0x80061218: mfc1        $t5, $f8
    ctx->r13 = (int32_t)ctx->f8.u32l;
    // 0x8006121C: nop

    // 0x80061220: sh          $t5, 0x0($t6)
    MEM_H(0X0, ctx->r14) = ctx->r13;
L_80061224:
    // 0x80061224: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
    // 0x80061228: ldc1        $f20, 0x10($sp)
    CHECK_FR(ctx, 20);
    ctx->f20.u64 = LD(ctx->r29, 0X10);
    // 0x8006122C: ldc1        $f22, 0x18($sp)
    CHECK_FR(ctx, 22);
    ctx->f22.u64 = LD(ctx->r29, 0X18);
    // 0x80061230: jr          $ra
    // 0x80061234: addiu       $sp, $sp, 0xB8
    ctx->r29 = ADD32(ctx->r29, 0XB8);
    return;
    // 0x80061234: addiu       $sp, $sp, 0xB8
    ctx->r29 = ADD32(ctx->r29, 0XB8);
;}
RECOMP_FUNC void env_static_80061238(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80061238: sw          $a2, 0x8($sp)
    MEM_W(0X8, ctx->r29) = ctx->r6;
    // 0x8006123C: sll         $t6, $a2, 16
    ctx->r14 = S32(ctx->r6 << 16);
    // 0x80061240: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    // 0x80061244: andi        $t8, $a3, 0xFFFF
    ctx->r24 = ctx->r7 & 0XFFFF;
    // 0x80061248: sra         $t9, $a1, 3
    ctx->r25 = S32(SIGNED(ctx->r5) >> 3);
    // 0x8006124C: or          $a3, $t8, $zero
    ctx->r7 = ctx->r24 | 0;
    // 0x80061250: sra         $a2, $t6, 16
    ctx->r6 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80061254: bne         $t9, $zero, L_80061264
    if (ctx->r25 != 0) {
            // 0x80061258: or          $a1, $t9, $zero
    ctx->r5 = ctx->r25 | 0;
    env_static_80061264(rdram, ctx);
    return;
    }
    // 0x80061258: or          $a1, $t9, $zero
    ctx->r5 = ctx->r25 | 0;
    // 0x8006125C: jr          $ra
    // 0x80061260: mov.s       $f0, $f12
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 12);
    ctx->f0.fl = ctx->f12.fl;
    return;
    // 0x80061260: mov.s       $f0, $f12
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 12);
    ctx->f0.fl = ctx->f12.fl;
;}
RECOMP_FUNC void env_static_80061264(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80061264: sll         $t0, $a2, 16
    ctx->r8 = S32(ctx->r6 << 16);
    // 0x80061268: mtc1        $t0, $f4
    ctx->f4.u32l = ctx->r8;
    // 0x8006126C: mtc1        $a3, $f8
    ctx->f8.u32l = ctx->r7;
    // 0x80061270: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x80061274: cvt.s.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
    // 0x80061278: bgez        $a3, L_80061290
    if (SIGNED(ctx->r7) >= 0) {
        // 0x8006127C: cvt.s.w     $f10, $f8
        CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    ctx->f10.fl = CVT_S_W(ctx->f8.u32l);
            goto L_80061290;
    }
    // 0x8006127C: cvt.s.w     $f10, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    ctx->f10.fl = CVT_S_W(ctx->f8.u32l);
    // 0x80061280: lui         $at, 0x4F80
    ctx->r1 = S32(0X4F80 << 16);
    // 0x80061284: mtc1        $at, $f16
    ctx->f16.u32l = ctx->r1;
    // 0x80061288: nop

    // 0x8006128C: add.s       $f10, $f10, $f16
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f10.fl); NAN_CHECK(ctx->f16.fl); 
    ctx->f10.fl = ctx->f10.fl + ctx->f16.fl;
L_80061290:
    // 0x80061290: lui         $at, 0x4780
    ctx->r1 = S32(0X4780 << 16);
    // 0x80061294: add.s       $f18, $f6, $f10
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f18.fl = ctx->f6.fl + ctx->f10.fl;
    // 0x80061298: mtc1        $at, $f4
    ctx->f4.u32l = ctx->r1;
    // 0x8006129C: lui         $at, 0x3F80
    ctx->r1 = S32(0X3F80 << 16);
    // 0x800612A0: mtc1        $at, $f2
    ctx->f2.u32l = ctx->r1;
    // 0x800612A4: addiu       $v1, $zero, 0x20
    ctx->r3 = ADD32(0, 0X20);
    // 0x800612A8: div.s       $f0, $f18, $f4
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f18.fl); NAN_CHECK(ctx->f4.fl); 
    ctx->f0.fl = DIV_S(ctx->f18.fl, ctx->f4.fl);
    // 0x800612AC: andi        $t1, $a1, 0x1
    ctx->r9 = ctx->r5 & 0X1;
L_800612B0:
    // 0x800612B0: beq         $t1, $zero, L_800612C0
    if (ctx->r9 == 0) {
        // 0x800612B4: sra         $t2, $a1, 1
        ctx->r10 = S32(SIGNED(ctx->r5) >> 1);
            goto L_800612C0;
    }
    // 0x800612B4: sra         $t2, $a1, 1
    ctx->r10 = S32(SIGNED(ctx->r5) >> 1);
    // 0x800612B8: mul.s       $f2, $f2, $f0
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f2.fl); NAN_CHECK(ctx->f0.fl); 
    ctx->f2.fl = MUL_S(ctx->f2.fl, ctx->f0.fl);
    // 0x800612BC: nop

L_800612C0:
    // 0x800612C0: beq         $t2, $zero, L_800612D8
    if (ctx->r10 == 0) {
        // 0x800612C4: or          $a1, $t2, $zero
        ctx->r5 = ctx->r10 | 0;
            goto L_800612D8;
    }
    // 0x800612C4: or          $a1, $t2, $zero
    ctx->r5 = ctx->r10 | 0;
    // 0x800612C8: addiu       $v0, $v0, 0x1
    ctx->r2 = ADD32(ctx->r2, 0X1);
    // 0x800612CC: mul.s       $f0, $f0, $f0
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f0.fl); NAN_CHECK(ctx->f0.fl); 
    ctx->f0.fl = MUL_S(ctx->f0.fl, ctx->f0.fl);
    // 0x800612D0: bnel        $v0, $v1, L_800612B0
    if (ctx->r2 != ctx->r3) {
        // 0x800612D4: andi        $t1, $a1, 0x1
        ctx->r9 = ctx->r5 & 0X1;
            goto L_800612B0;
    }
    goto skip_0;
    // 0x800612D4: andi        $t1, $a1, 0x1
    ctx->r9 = ctx->r5 & 0X1;
    skip_0:
L_800612D8:
    // 0x800612D8: mul.s       $f0, $f12, $f2
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 2);
    NAN_CHECK(ctx->f12.fl); NAN_CHECK(ctx->f2.fl); 
    ctx->f0.fl = MUL_S(ctx->f12.fl, ctx->f2.fl);
    // 0x800612DC: nop

    // 0x800612E0: jr          $ra
    // 0x800612E4: nop

    return;
    // 0x800612E4: nop

;}
RECOMP_FUNC void osGbpakReadWrite(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80065910: addiu       $sp, $sp, -0x40
    ctx->r29 = ADD32(ctx->r29, -0X40);
    // 0x80065914: sw          $s1, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r17;
    // 0x80065918: sw          $ra, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r31;
    // 0x8006591C: sw          $s5, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r21;
    // 0x80065920: sw          $s4, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r20;
    // 0x80065924: sw          $s3, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r19;
    // 0x80065928: sw          $s2, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r18;
    // 0x8006592C: sw          $s0, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r16;
    // 0x80065930: sw          $a1, 0x44($sp)
    MEM_W(0X44, ctx->r29) = ctx->r5;
    // 0x80065934: sw          $a2, 0x48($sp)
    MEM_W(0X48, ctx->r29) = ctx->r6;
    // 0x80065938: lbu         $t6, 0x64($a0)
    ctx->r14 = MEM_BU(ctx->r4, 0X64);
    // 0x8006593C: andi        $s1, $a2, 0xFFFF
    ctx->r17 = ctx->r6 & 0XFFFF;
    // 0x80065940: sra         $v0, $s1, 14
    ctx->r2 = S32(SIGNED(ctx->r17) >> 14);
    // 0x80065944: andi        $s5, $v0, 0xFF
    ctx->r21 = ctx->r2 & 0XFF;
    // 0x80065948: or          $s2, $a0, $zero
    ctx->r18 = ctx->r4 | 0;
    // 0x8006594C: or          $s4, $a3, $zero
    ctx->r20 = ctx->r7 | 0;
    // 0x80065950: beq         $t6, $s5, L_80065970
    if (ctx->r14 == ctx->r21) {
        // 0x80065954: andi        $s3, $v0, 0xFF
        ctx->r19 = ctx->r2 & 0XFF;
            goto L_80065970;
    }
    // 0x80065954: andi        $s3, $v0, 0xFF
    ctx->r19 = ctx->r2 & 0XFF;
    // 0x80065958: jal         0x80065AD0
    // 0x8006595C: andi        $a1, $s5, 0xFF
    ctx->r5 = ctx->r21 & 0XFF;
    __osGbpakSetBank(rdram, ctx);
        goto after_0;
    // 0x8006595C: andi        $a1, $s5, 0xFF
    ctx->r5 = ctx->r21 & 0XFF;
    after_0:
    // 0x80065960: beq         $v0, $zero, L_80065970
    if (ctx->r2 == 0) {
        // 0x80065964: sw          $v0, 0x38($sp)
        MEM_W(0X38, ctx->r29) = ctx->r2;
            goto L_80065970;
    }
    // 0x80065964: sw          $v0, 0x38($sp)
    MEM_W(0X38, ctx->r29) = ctx->r2;
    // 0x80065968: b           L_80065AB0
    // 0x8006596C: lw          $ra, 0x34($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X34);
        goto L_80065AB0;
    // 0x8006596C: lw          $ra, 0x34($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X34);
L_80065970:
    // 0x80065970: lhu         $v0, 0x52($sp)
    ctx->r2 = MEM_HU(ctx->r29, 0X52);
    // 0x80065974: lhu         $t1, 0x46($sp)
    ctx->r9 = MEM_HU(ctx->r29, 0X46);
    // 0x80065978: ori         $s0, $s1, 0xC000
    ctx->r16 = ctx->r17 | 0XC000;
    // 0x8006597C: sra         $t7, $v0, 5
    ctx->r15 = S32(SIGNED(ctx->r2) >> 5);
    // 0x80065980: andi        $t8, $t7, 0xFFFF
    ctx->r24 = ctx->r15 & 0XFFFF;
    // 0x80065984: sra         $t9, $s0, 5
    ctx->r25 = S32(SIGNED(ctx->r16) >> 5);
    // 0x80065988: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x8006598C: lw          $v1, 0x38($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X38);
    // 0x80065990: or          $v0, $t8, $zero
    ctx->r2 = ctx->r24 | 0;
    // 0x80065994: bne         $t1, $at, L_80065A20
    if (ctx->r9 != ctx->r1) {
        // 0x80065998: andi        $s0, $t9, 0xFFFF
        ctx->r16 = ctx->r25 & 0XFFFF;
            goto L_80065A20;
    }
    // 0x80065998: andi        $s0, $t9, 0xFFFF
    ctx->r16 = ctx->r25 & 0XFFFF;
    // 0x8006599C: or          $s1, $zero, $zero
    ctx->r17 = 0 | 0;
    // 0x800659A0: blez        $t8, L_80065A98
    if (SIGNED(ctx->r24) <= 0) {
        // 0x800659A4: or          $s5, $t8, $zero
        ctx->r21 = ctx->r24 | 0;
            goto L_80065A98;
    }
    // 0x800659A4: or          $s5, $t8, $zero
    ctx->r21 = ctx->r24 | 0;
L_800659A8:
    // 0x800659A8: lw          $a0, 0x4($s2)
    ctx->r4 = MEM_W(ctx->r18, 0X4);
    // 0x800659AC: lw          $a1, 0x8($s2)
    ctx->r5 = MEM_W(ctx->r18, 0X8);
    // 0x800659B0: sw          $zero, 0x10($sp)
    MEM_W(0X10, ctx->r29) = 0;
    // 0x800659B4: andi        $a2, $s0, 0xFFFF
    ctx->r6 = ctx->r16 & 0XFFFF;
    // 0x800659B8: jal         0x80063810
    // 0x800659BC: or          $a3, $s4, $zero
    ctx->r7 = ctx->r20 | 0;
    __osContRamWrite_recomp(rdram, ctx);
        goto after_1;
    // 0x800659BC: or          $a3, $s4, $zero
    ctx->r7 = ctx->r20 | 0;
    after_1:
    // 0x800659C0: bne         $v0, $zero, L_80065A98
    if (ctx->r2 != 0) {
        // 0x800659C4: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_80065A98;
    }
    // 0x800659C4: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x800659C8: addiu       $s0, $s0, 0x1
    ctx->r16 = ADD32(ctx->r16, 0X1);
    // 0x800659CC: andi        $t2, $s0, 0xFFFF
    ctx->r10 = ctx->r16 & 0XFFFF;
    // 0x800659D0: slti        $at, $t2, 0x800
    ctx->r1 = SIGNED(ctx->r10) < 0X800 ? 1 : 0;
    // 0x800659D4: bne         $at, $zero, L_80065A0C
    if (ctx->r1 != 0) {
        // 0x800659D8: or          $s0, $t2, $zero
        ctx->r16 = ctx->r10 | 0;
            goto L_80065A0C;
    }
    // 0x800659D8: or          $s0, $t2, $zero
    ctx->r16 = ctx->r10 | 0;
    // 0x800659DC: addiu       $t3, $s5, -0x1
    ctx->r11 = ADD32(ctx->r21, -0X1);
    // 0x800659E0: slt         $at, $s1, $t3
    ctx->r1 = SIGNED(ctx->r17) < SIGNED(ctx->r11) ? 1 : 0;
    // 0x800659E4: beq         $at, $zero, L_80065A0C
    if (ctx->r1 == 0) {
        // 0x800659E8: or          $a0, $s2, $zero
        ctx->r4 = ctx->r18 | 0;
            goto L_80065A0C;
    }
    // 0x800659E8: or          $a0, $s2, $zero
    ctx->r4 = ctx->r18 | 0;
    // 0x800659EC: addiu       $s3, $s3, 0x1
    ctx->r19 = ADD32(ctx->r19, 0X1);
    // 0x800659F0: andi        $t4, $s3, 0xFF
    ctx->r12 = ctx->r19 & 0XFF;
    // 0x800659F4: or          $s3, $t4, $zero
    ctx->r19 = ctx->r12 | 0;
    // 0x800659F8: jal         0x80065AD0
    // 0x800659FC: andi        $a1, $t4, 0xFF
    ctx->r5 = ctx->r12 & 0XFF;
    __osGbpakSetBank(rdram, ctx);
        goto after_2;
    // 0x800659FC: andi        $a1, $t4, 0xFF
    ctx->r5 = ctx->r12 & 0XFF;
    after_2:
    // 0x80065A00: bne         $v0, $zero, L_80065A98
    if (ctx->r2 != 0) {
        // 0x80065A04: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_80065A98;
    }
    // 0x80065A04: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x80065A08: addiu       $s0, $zero, 0x600
    ctx->r16 = ADD32(0, 0X600);
L_80065A0C:
    // 0x80065A0C: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x80065A10: bne         $s1, $s5, L_800659A8
    if (ctx->r17 != ctx->r21) {
        // 0x80065A14: addiu       $s4, $s4, 0x20
        ctx->r20 = ADD32(ctx->r20, 0X20);
            goto L_800659A8;
    }
    // 0x80065A14: addiu       $s4, $s4, 0x20
    ctx->r20 = ADD32(ctx->r20, 0X20);
    // 0x80065A18: b           L_80065A9C
    // 0x80065A1C: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
        goto L_80065A9C;
    // 0x80065A1C: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
L_80065A20:
    // 0x80065A20: or          $s1, $zero, $zero
    ctx->r17 = 0 | 0;
    // 0x80065A24: blez        $v0, L_80065A98
    if (SIGNED(ctx->r2) <= 0) {
        // 0x80065A28: or          $s5, $v0, $zero
        ctx->r21 = ctx->r2 | 0;
            goto L_80065A98;
    }
    // 0x80065A28: or          $s5, $v0, $zero
    ctx->r21 = ctx->r2 | 0;
L_80065A2C:
    // 0x80065A2C: lw          $a0, 0x4($s2)
    ctx->r4 = MEM_W(ctx->r18, 0X4);
    // 0x80065A30: lw          $a1, 0x8($s2)
    ctx->r5 = MEM_W(ctx->r18, 0X8);
    // 0x80065A34: andi        $a2, $s0, 0xFFFF
    ctx->r6 = ctx->r16 & 0XFFFF;
    // 0x80065A38: jal         0x80063A60
    // 0x80065A3C: or          $a3, $s4, $zero
    ctx->r7 = ctx->r20 | 0;
    __osContRamRead_recomp(rdram, ctx);
        goto after_3;
    // 0x80065A3C: or          $a3, $s4, $zero
    ctx->r7 = ctx->r20 | 0;
    after_3:
    // 0x80065A40: bne         $v0, $zero, L_80065A98
    if (ctx->r2 != 0) {
        // 0x80065A44: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_80065A98;
    }
    // 0x80065A44: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x80065A48: addiu       $s0, $s0, 0x1
    ctx->r16 = ADD32(ctx->r16, 0X1);
    // 0x80065A4C: andi        $t5, $s0, 0xFFFF
    ctx->r13 = ctx->r16 & 0XFFFF;
    // 0x80065A50: slti        $at, $t5, 0x800
    ctx->r1 = SIGNED(ctx->r13) < 0X800 ? 1 : 0;
    // 0x80065A54: bne         $at, $zero, L_80065A8C
    if (ctx->r1 != 0) {
        // 0x80065A58: or          $s0, $t5, $zero
        ctx->r16 = ctx->r13 | 0;
            goto L_80065A8C;
    }
    // 0x80065A58: or          $s0, $t5, $zero
    ctx->r16 = ctx->r13 | 0;
    // 0x80065A5C: addiu       $t6, $s5, -0x1
    ctx->r14 = ADD32(ctx->r21, -0X1);
    // 0x80065A60: slt         $at, $s1, $t6
    ctx->r1 = SIGNED(ctx->r17) < SIGNED(ctx->r14) ? 1 : 0;
    // 0x80065A64: beq         $at, $zero, L_80065A8C
    if (ctx->r1 == 0) {
        // 0x80065A68: or          $a0, $s2, $zero
        ctx->r4 = ctx->r18 | 0;
            goto L_80065A8C;
    }
    // 0x80065A68: or          $a0, $s2, $zero
    ctx->r4 = ctx->r18 | 0;
    // 0x80065A6C: addiu       $s3, $s3, 0x1
    ctx->r19 = ADD32(ctx->r19, 0X1);
    // 0x80065A70: andi        $t7, $s3, 0xFF
    ctx->r15 = ctx->r19 & 0XFF;
    // 0x80065A74: or          $s3, $t7, $zero
    ctx->r19 = ctx->r15 | 0;
    // 0x80065A78: jal         0x80065AD0
    // 0x80065A7C: andi        $a1, $t7, 0xFF
    ctx->r5 = ctx->r15 & 0XFF;
    __osGbpakSetBank(rdram, ctx);
        goto after_4;
    // 0x80065A7C: andi        $a1, $t7, 0xFF
    ctx->r5 = ctx->r15 & 0XFF;
    after_4:
    // 0x80065A80: bne         $v0, $zero, L_80065A98
    if (ctx->r2 != 0) {
        // 0x80065A84: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_80065A98;
    }
    // 0x80065A84: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x80065A88: addiu       $s0, $zero, 0x600
    ctx->r16 = ADD32(0, 0X600);
L_80065A8C:
    // 0x80065A8C: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x80065A90: bne         $s1, $s5, L_80065A2C
    if (ctx->r17 != ctx->r21) {
        // 0x80065A94: addiu       $s4, $s4, 0x20
        ctx->r20 = ADD32(ctx->r20, 0X20);
            goto L_80065A2C;
    }
    // 0x80065A94: addiu       $s4, $s4, 0x20
    ctx->r20 = ADD32(ctx->r20, 0X20);
L_80065A98:
    // 0x80065A98: addiu       $at, $zero, 0x2
    ctx->r1 = ADD32(0, 0X2);
L_80065A9C:
    // 0x80065A9C: bnel        $v1, $at, L_80065AAC
    if (ctx->r3 != ctx->r1) {
        // 0x80065AA0: or          $v0, $v1, $zero
        ctx->r2 = ctx->r3 | 0;
            goto L_80065AAC;
    }
    goto skip_0;
    // 0x80065AA0: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
    skip_0:
    // 0x80065AA4: addiu       $v1, $zero, 0x4
    ctx->r3 = ADD32(0, 0X4);
    // 0x80065AA8: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
L_80065AAC:
    // 0x80065AAC: lw          $ra, 0x34($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X34);
L_80065AB0:
    // 0x80065AB0: lw          $s0, 0x1C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X1C);
    // 0x80065AB4: lw          $s1, 0x20($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X20);
    // 0x80065AB8: lw          $s2, 0x24($sp)
    ctx->r18 = MEM_W(ctx->r29, 0X24);
    // 0x80065ABC: lw          $s3, 0x28($sp)
    ctx->r19 = MEM_W(ctx->r29, 0X28);
    // 0x80065AC0: lw          $s4, 0x2C($sp)
    ctx->r20 = MEM_W(ctx->r29, 0X2C);
    // 0x80065AC4: lw          $s5, 0x30($sp)
    ctx->r21 = MEM_W(ctx->r29, 0X30);
    // 0x80065AC8: jr          $ra
    // 0x80065ACC: addiu       $sp, $sp, 0x40
    ctx->r29 = ADD32(ctx->r29, 0X40);
    return;
    // 0x80065ACC: addiu       $sp, $sp, 0x40
    ctx->r29 = ADD32(ctx->r29, 0X40);
;}
RECOMP_FUNC void fragment32_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x81100000: j           L_811007F8
    // 0x81100004: nop

    func_811007F8(rdram, ctx);
    return;
    // 0x81100004: nop

;}
RECOMP_FUNC void fragment33_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x81300000: j           L_81302E58
    // 0x81300004: nop

    func_81302E58(rdram, ctx);
    return;
    // 0x81300004: nop

;}
RECOMP_FUNC void fragment34_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x81400000: j           L_81400020
    // 0x81400004: nop

    func_81400020(rdram, ctx);
    return;
    // 0x81400004: nop

;}
RECOMP_FUNC void fragment35_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82000000: j           L_820003A4
    // 0x82000004: nop

    func_820003A4(rdram, ctx);
    return;
    // 0x82000004: nop

;}
RECOMP_FUNC void fragment36_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82100000: j           L_82100C98
    // 0x82100004: nop

    func_82100C98(rdram, ctx);
    return;
    // 0x82100004: nop

;}
RECOMP_FUNC void fragment37_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82200000: j           L_82202DC4
    // 0x82200004: nop

    func_82202DC4(rdram, ctx);
    return;
    // 0x82200004: nop

;}
RECOMP_FUNC void fragment38_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82300000: j           L_823057E4
    // 0x82300004: nop

    func_823057E4(rdram, ctx);
    return;
    // 0x82300004: nop

;}
RECOMP_FUNC void fragment39_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82500000: j           L_825046AC
    // 0x82500004: nop

    func_825046AC(rdram, ctx);
    return;
    // 0x82500004: nop

;}
RECOMP_FUNC void fragment50_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82600000: j           L_82603D20
    // 0x82600004: nop

    func_82603D20(rdram, ctx);
    return;
    // 0x82600004: nop

;}
RECOMP_FUNC void fragment52_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82800000: j           L_82800390
    // 0x82800004: nop

    func_82900390(rdram, ctx);
    return;
    // 0x82800004: nop

;}
RECOMP_FUNC void fragment53_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82A00000: j           L_82A00224
    // 0x82A00004: nop

    func_82A00224(rdram, ctx);
    return;
    // 0x82A00004: nop

;}
RECOMP_FUNC void fragment54_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82B00000: j           L_82B0104C
    // 0x82B00004: nop

    func_82B0104C(rdram, ctx);
    return;
    // 0x82B00004: nop

;}
RECOMP_FUNC void fragment56_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82C00000: j           L_82C014FC
    // 0x82C00004: nop

    func_82C014FC(rdram, ctx);
    return;
    // 0x82C00004: nop

;}
RECOMP_FUNC void fragment57_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82D00000: j           L_82D06D0C
    // 0x82D00004: nop

    func_82D06D0C(rdram, ctx);
    return;
    // 0x82D00004: nop

;}
RECOMP_FUNC void fragment60_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82E00000: j           L_82E00F2C
    // 0x82E00004: nop

    func_82E00F2C(rdram, ctx);
    return;
    // 0x82E00004: nop

;}
RECOMP_FUNC void fragment41_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x82F00000: j           L_82F01234
    // 0x82F00004: nop

    func_82F01234(rdram, ctx);
    return;
    // 0x82F00004: nop

;}
RECOMP_FUNC void fragment55_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83000000: j           L_83002120
    // 0x83000004: nop

    func_83002120(rdram, ctx);
    return;
    // 0x83000004: nop

;}
RECOMP_FUNC void fragment40_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83100000: j           L_83101A98
    // 0x83100004: nop

    func_83101A98(rdram, ctx);
    return;
    // 0x83100004: nop

;}
RECOMP_FUNC void fragment66_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83200000: j           L_83201DD4
    // 0x83200004: nop

    func_83201DD4(rdram, ctx);
    return;
    // 0x83200004: nop

;}
RECOMP_FUNC void fragment42_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83300000: j           L_83302FD8
    // 0x83300004: nop

    func_83302FD8(rdram, ctx);
    return;
    // 0x83300004: nop

;}
RECOMP_FUNC void fragment43_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83400000: j           L_83400020
    // 0x83400004: nop

    func_83400020(rdram, ctx);
    return;
    // 0x83400004: nop

;}
RECOMP_FUNC void fragment44_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83500000: j           L_83503C9C
    // 0x83500004: nop

    func_83503C9C(rdram, ctx);
    return;
    // 0x83500004: nop

;}
RECOMP_FUNC void fragment45_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83600000: j           L_836030A8
    // 0x83600004: nop

    func_836030A8(rdram, ctx);
    return;
    // 0x83600004: nop

;}
RECOMP_FUNC void fragment46_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83700000: j           L_837002EC
    // 0x83700004: nop

    func_837002EC(rdram, ctx);
    return;
    // 0x83700004: nop

;}
RECOMP_FUNC void fragment47_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83800000: j           L_83800730
    // 0x83800004: nop

    func_83800730(rdram, ctx);
    return;
    // 0x83800004: nop

;}
RECOMP_FUNC void fragment48_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83900000: j           L_839004F4
    // 0x83900004: nop

    func_839004F4(rdram, ctx);
    return;
    // 0x83900004: nop

;}
RECOMP_FUNC void fragment49_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x83A00000: j           L_83A00A4C
    // 0x83A00004: nop

    func_83A00A4C(rdram, ctx);
    return;
    // 0x83A00004: nop

;}
RECOMP_FUNC void fragment58_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84000000: j           L_84002A84
    // 0x84000004: nop

    func_84002A84(rdram, ctx);
    return;
    // 0x84000004: nop

;}
RECOMP_FUNC void fragment59_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84100000: j           L_841022C0
    // 0x84100004: nop

    func_841022C0(rdram, ctx);
    return;
    // 0x84100004: nop

;}
RECOMP_FUNC void fragment61_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84200000: j           L_84203E6C
    // 0x84200004: nop

    func_84203E6C(rdram, ctx);
    return;
    // 0x84200004: nop

;}
RECOMP_FUNC void fragment62_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84300000: j           L_84301A2C
    // 0x84300004: nop

    func_84301A2C(rdram, ctx);
    return;
    // 0x84300004: nop

;}
RECOMP_FUNC void fragment64_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84800000: j           L_84803368
    // 0x84800004: nop

    func_84803368(rdram, ctx);
    return;
    // 0x84800004: nop

;}
RECOMP_FUNC void fragment65_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84A00000: j           L_84A02D14
    // 0x84A00004: nop

    func_84A02D14(rdram, ctx);
    return;
    // 0x84A00004: nop

;}
RECOMP_FUNC void fragment63_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x84B00000: j           L_84B03194
    // 0x84B00004: nop

    func_84B03194(rdram, ctx);
    return;
    // 0x84B00004: nop

;}
RECOMP_FUNC void fragment6_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86000000: j           L_86002778
    // 0x86000004: nop

    func_86002778(rdram, ctx);
    return;
    // 0x86000004: nop

;}
RECOMP_FUNC void fragment7_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86100000: j           L_86104474
    // 0x86100004: nop

    func_86104474(rdram, ctx);
    return;
    // 0x86100004: nop

;}
RECOMP_FUNC void fragment8_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86200000: j           L_8620369C
    // 0x86200004: nop

    func_8620369C(rdram, ctx);
    return;
    // 0x86200004: nop

;}
RECOMP_FUNC void fragment9_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86300000: j           L_86301474
    // 0x86300004: nop

    func_86301474(rdram, ctx);
    return;
    // 0x86300004: nop

;}
RECOMP_FUNC void fragment10_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86400000: j           L_864025A0
    // 0x86400004: nop

    func_864025A0(rdram, ctx);
    return;
    // 0x86400004: nop

;}
RECOMP_FUNC void fragment11_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86500000: j           L_86501E9C
    // 0x86500004: nop

    func_86501E9C(rdram, ctx);
    return;
    // 0x86500004: nop

;}
RECOMP_FUNC void fragment12_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86600000: j           L_8660070C
    // 0x86600004: nop

    func_8660070C(rdram, ctx);
    return;
    // 0x86600004: nop

;}
RECOMP_FUNC void fragment13_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86700000: j           L_867006FC
    // 0x86700004: nop

    func_867006FC(rdram, ctx);
    return;
    // 0x86700004: nop

;}
RECOMP_FUNC void fragment14_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86800000: j           L_86801E2C
    // 0x86800004: nop

    func_86801E2C(rdram, ctx);
    return;
    // 0x86800004: nop

;}
RECOMP_FUNC void fragment15_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86900000: j           L_86902098
    // 0x86900004: nop

    func_86902098(rdram, ctx);
    return;
    // 0x86900004: nop

;}
RECOMP_FUNC void fragment16_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86A00000: j           L_86A00ED8
    // 0x86A00004: nop

    func_86A00ED8(rdram, ctx);
    return;
    // 0x86A00004: nop

;}
RECOMP_FUNC void fragment17_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86B00000: j           L_86B00020
    // 0x86B00004: nop

    func_86B00020(rdram, ctx);
    return;
    // 0x86B00004: nop

;}
RECOMP_FUNC void fragment18_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86C00000: j           L_86C046B0
    // 0x86C00004: nop

    ekansMinigameLoad(rdram, ctx);
    return;
    // 0x86C00004: nop

;}
RECOMP_FUNC void fragment19_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86D00000: j           L_86D003EC
    // 0x86D00004: nop

    func_86D003EC(rdram, ctx);
    return;
    // 0x86D00004: nop

;}
RECOMP_FUNC void fragment20_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86E00000: j           L_86E02E40
    // 0x86E00004: nop

    metapodMinigameLoad(rdram, ctx);
    return;
    // 0x86E00004: nop

;}
RECOMP_FUNC void fragment21_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x86F00000: j           L_86F02520
    // 0x86F00004: nop

    sandshrewMinigameLoad(rdram, ctx);
    return;
    // 0x86F00004: nop

;}
RECOMP_FUNC void fragment2_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x87800000: j           L_87800020
    // 0x87800004: nop

    func_87800020(rdram, ctx);
    return;
    // 0x87800004: nop

;}
RECOMP_FUNC void fragment3_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x87900000: j           L_87900020
    // 0x87900004: nop

    func_87900020(rdram, ctx);
    return;
    // 0x87900004: nop

;}
RECOMP_FUNC void fragment4_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x87A00000: j           L_87A00020
    // 0x87A00004: nop

    func_87A00020(rdram, ctx);
    return;
    // 0x87A00004: nop

;}
RECOMP_FUNC void fragment5_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x87B00000: j           L_87B00020
    // 0x87B00004: nop

    func_87B00020(rdram, ctx);
    return;
    // 0x87B00004: nop

;}
RECOMP_FUNC void fragment22_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88000000: j           L_88002628
    // 0x88000004: nop

    func_88002628(rdram, ctx);
    return;
    // 0x88000004: nop

;}
RECOMP_FUNC void fragment23_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88200000: j           L_88200190
    // 0x88200004: nop

    func_88200190(rdram, ctx);
    return;
    // 0x88200004: nop

;}
RECOMP_FUNC void fragment24_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88300000: j           L_88308E84
    // 0x88300004: nop

    func_88308E84(rdram, ctx);
    return;
    // 0x88300004: nop

;}
RECOMP_FUNC void fragment25_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88400000: j           L_88400020
    // 0x88400004: nop

    func_88400020(rdram, ctx);
    return;
    // 0x88400004: nop

;}
RECOMP_FUNC void fragment26_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88500000: j           L_88500020
    // 0x88500004: nop

    func_88500020(rdram, ctx);
    return;
    // 0x88500004: nop

;}
RECOMP_FUNC void fragment27_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88600000: j           L_88605A0C
    // 0x88600004: nop

    func_88605A0C(rdram, ctx);
    return;
    // 0x88600004: nop

;}
RECOMP_FUNC void fragment28_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88800000: j           L_888044BC
    // 0x88800004: nop

    func_888044BC(rdram, ctx);
    return;
    // 0x88800004: nop

;}
RECOMP_FUNC void fragment29_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x88900000: j           L_88900020
    // 0x88900004: nop

    func_88900020(rdram, ctx);
    return;
    // 0x88900004: nop

;}
RECOMP_FUNC void fragment67_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F000000: j           L_8F000020
    // 0x8F000004: nop

    func_8F000020(rdram, ctx);
    return;
    // 0x8F000004: nop

;}
RECOMP_FUNC void fragment68_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F100000: j           L_8F100020
    // 0x8F100004: nop

    func_8F100020(rdram, ctx);
    return;
    // 0x8F100004: nop

;}
RECOMP_FUNC void fragment69_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F200000: j           L_8F200020
    // 0x8F200004: nop

    func_8F200020(rdram, ctx);
    return;
    // 0x8F200004: nop

;}
RECOMP_FUNC void fragment70_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F300000: j           L_8F300020
    // 0x8F300004: nop

    func_8F300020(rdram, ctx);
    return;
    // 0x8F300004: nop

;}
RECOMP_FUNC void fragment71_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F400000: j           L_8F400020
    // 0x8F400004: nop

    func_8F400020(rdram, ctx);
    return;
    // 0x8F400004: nop

;}
RECOMP_FUNC void fragment72_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F500000: j           L_8F500020
    // 0x8F500004: nop

    func_8F500020(rdram, ctx);
    return;
    // 0x8F500004: nop

;}
RECOMP_FUNC void fragment73_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8F600000: j           L_8F600020
    // 0x8F600004: nop

    func_8F600020(rdram, ctx);
    return;
    // 0x8F600004: nop

;}
RECOMP_FUNC void fragment75_entry(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8FA00000: j           L_8FA0051C
    // 0x8FA00004: nop

    func_8FA0051C(rdram, ctx);
    return;
    // 0x8FA00004: nop

;}
RECOMP_FUNC void static_5_800475A4(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x800475A4: addiu       $sp, $sp, -0x48
    ctx->r29 = ADD32(ctx->r29, -0X48);
    // 0x800475A8: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x800475AC: sw          $s1, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r17;
    // 0x800475B0: sw          $s0, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r16;
    // 0x800475B4: sw          $a1, 0x4C($sp)
    MEM_W(0X4C, ctx->r29) = ctx->r5;
    // 0x800475B8: sw          $a2, 0x50($sp)
    MEM_W(0X50, ctx->r29) = ctx->r6;
    // 0x800475BC: lw          $t6, 0x84($a0)
    ctx->r14 = MEM_W(ctx->r4, 0X84);
    // 0x800475C0: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x800475C4: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x800475C8: bne         $t6, $at, L_800475D8
    if (ctx->r14 != ctx->r1) {
        // 0x800475CC: nop
    
            goto L_800475D8;
    }
    // 0x800475CC: nop

    // 0x800475D0: bne         $a3, $zero, L_800475E0
    if (ctx->r7 != 0) {
        // 0x800475D4: or          $a0, $s0, $zero
        ctx->r4 = ctx->r16 | 0;
            goto L_800475E0;
    }
    // 0x800475D4: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
L_800475D8:
    // 0x800475D8: b           L_800477BC
    // 0x800475DC: lw          $v0, 0x58($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X58);
        goto L_800477BC;
    // 0x800475DC: lw          $v0, 0x58($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X58);
L_800475E0:
    // 0x800475E0: lw          $a1, 0x4C($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X4C);
    // 0x800475E4: jal         0x8004F350
    // 0x800475E8: lw          $a2, 0x58($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X58);
    n_alResamplePull(rdram, ctx);
        goto after_0;
    // 0x800475E8: lw          $a2, 0x58($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X58);
    after_0:
    // 0x800475EC: lw          $t7, 0x78($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X78);
    // 0x800475F0: or          $s1, $v0, $zero
    ctx->r17 = ctx->r2 | 0;
    // 0x800475F4: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x800475F8: beq         $t7, $zero, L_80047780
    if (ctx->r15 == 0) {
        // 0x800475FC: lui         $t9, 0x300
        ctx->r25 = S32(0X300 << 16);
            goto L_80047780;
    }
    // 0x800475FC: lui         $t9, 0x300
    ctx->r25 = S32(0X300 << 16);
    // 0x80047600: lh          $t8, 0x58($s0)
    ctx->r24 = MEM_H(ctx->r16, 0X58);
    // 0x80047604: lui         $t0, 0x8008
    ctx->r8 = S32(0X8008 << 16);
    // 0x80047608: sw          $zero, 0x78($s0)
    MEM_W(0X78, ctx->r16) = 0;
    // 0x8004760C: sll         $t9, $t8, 1
    ctx->r25 = S32(ctx->r24 << 1);
    // 0x80047610: addu        $t0, $t0, $t9
    ctx->r8 = ADD32(ctx->r8, ctx->r25);
    // 0x80047614: lh          $t0, -0x7A00($t0)
    ctx->r8 = MEM_H(ctx->r8, -0X7A00);
    // 0x80047618: lh          $t1, 0x5A($s0)
    ctx->r9 = MEM_H(ctx->r16, 0X5A);
    // 0x8004761C: lh          $t4, 0x5C($s0)
    ctx->r12 = MEM_H(ctx->r16, 0X5C);
    // 0x80047620: lw          $t6, 0x74($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X74);
    // 0x80047624: multu       $t0, $t1
    result = U64(U32(ctx->r8)) * U64(U32(ctx->r9)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x80047628: mtc1        $t4, $f4
    ctx->f4.u32l = ctx->r12;
    // 0x8004762C: addiu       $t7, $s0, 0x64
    ctx->r15 = ADD32(ctx->r16, 0X64);
    // 0x80047630: cvt.d.w     $f12, $f4
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 4);
    ctx->f12.d = CVT_D_W(ctx->f4.u32l);
    // 0x80047634: mflo        $t2
    ctx->r10 = lo;
    // 0x80047638: sra         $t3, $t2, 15
    ctx->r11 = S32(SIGNED(ctx->r10) >> 15);
    // 0x8004763C: sh          $t3, 0x68($s0)
    MEM_H(0X68, ctx->r16) = ctx->r11;
    // 0x80047640: lh          $t5, 0x68($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X68);
    // 0x80047644: sw          $t7, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r15;
    // 0x80047648: sw          $t6, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r14;
    // 0x8004764C: mtc1        $t5, $f6
    ctx->f6.u32l = ctx->r13;
    // 0x80047650: jal         0x800477D0
    // 0x80047654: cvt.d.w     $f14, $f6
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 6);
    ctx->f14.d = CVT_D_W(ctx->f6.u32l);
    static_5_800477D0(rdram, ctx);
        goto after_1;
    // 0x80047654: cvt.d.w     $f14, $f6
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 6);
    ctx->f14.d = CVT_D_W(ctx->f6.u32l);
    after_1:
    // 0x80047658: lh          $t8, 0x58($s0)
    ctx->r24 = MEM_H(ctx->r16, 0X58);
    // 0x8004765C: lui         $t1, 0x8008
    ctx->r9 = S32(0X8008 << 16);
    // 0x80047660: sh          $v0, 0x66($s0)
    MEM_H(0X66, ctx->r16) = ctx->r2;
    // 0x80047664: sll         $t9, $t8, 1
    ctx->r25 = S32(ctx->r24 << 1);
    // 0x80047668: negu        $t0, $t9
    ctx->r8 = SUB32(0, ctx->r25);
    // 0x8004766C: addu        $t1, $t1, $t0
    ctx->r9 = ADD32(ctx->r9, ctx->r8);
    // 0x80047670: lh          $t1, -0x7902($t1)
    ctx->r9 = MEM_H(ctx->r9, -0X7902);
    // 0x80047674: lh          $t2, 0x5A($s0)
    ctx->r10 = MEM_H(ctx->r16, 0X5A);
    // 0x80047678: lh          $t5, 0x5E($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X5E);
    // 0x8004767C: lw          $t7, 0x74($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X74);
    // 0x80047680: multu       $t1, $t2
    result = U64(U32(ctx->r9)) * U64(U32(ctx->r10)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x80047684: mtc1        $t5, $f8
    ctx->f8.u32l = ctx->r13;
    // 0x80047688: addiu       $t8, $s0, 0x6A
    ctx->r24 = ADD32(ctx->r16, 0X6A);
    // 0x8004768C: cvt.d.w     $f12, $f8
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 8);
    ctx->f12.d = CVT_D_W(ctx->f8.u32l);
    // 0x80047690: mflo        $t3
    ctx->r11 = lo;
    // 0x80047694: sra         $t4, $t3, 15
    ctx->r12 = S32(SIGNED(ctx->r11) >> 15);
    // 0x80047698: sh          $t4, 0x6E($s0)
    MEM_H(0X6E, ctx->r16) = ctx->r12;
    // 0x8004769C: lh          $t6, 0x6E($s0)
    ctx->r14 = MEM_H(ctx->r16, 0X6E);
    // 0x800476A0: sw          $t8, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r24;
    // 0x800476A4: sw          $t7, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r15;
    // 0x800476A8: mtc1        $t6, $f10
    ctx->f10.u32l = ctx->r14;
    // 0x800476AC: jal         0x800477D0
    // 0x800476B0: cvt.d.w     $f14, $f10
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 10);
    ctx->f14.d = CVT_D_W(ctx->f10.u32l);
    static_5_800477D0(rdram, ctx);
        goto after_2;
    // 0x800476B0: cvt.d.w     $f14, $f10
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 10);
    ctx->f14.d = CVT_D_W(ctx->f10.u32l);
    after_2:
    // 0x800476B4: lh          $t9, 0x68($s0)
    ctx->r25 = MEM_H(ctx->r16, 0X68);
    // 0x800476B8: lui         $at, 0x900
    ctx->r1 = S32(0X900 << 16);
    // 0x800476BC: sh          $v0, 0x6C($s0)
    MEM_H(0X6C, ctx->r16) = ctx->r2;
    // 0x800476C0: andi        $t0, $t9, 0xFFFF
    ctx->r8 = ctx->r25 & 0XFFFF;
    // 0x800476C4: or          $t1, $t0, $at
    ctx->r9 = ctx->r8 | ctx->r1;
    // 0x800476C8: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x800476CC: sw          $t1, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r9;
    // 0x800476D0: lh          $t3, 0x66($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X66);
    // 0x800476D4: lhu         $t6, 0x64($s0)
    ctx->r14 = MEM_HU(ctx->r16, 0X64);
    // 0x800476D8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x800476DC: sll         $t4, $t3, 16
    ctx->r12 = S32(ctx->r11 << 16);
    // 0x800476E0: or          $t7, $t4, $t6
    ctx->r15 = ctx->r12 | ctx->r14;
    // 0x800476E4: sw          $t7, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r15;
    // 0x800476E8: lh          $t8, 0x5C($s0)
    ctx->r24 = MEM_H(ctx->r16, 0X5C);
    // 0x800476EC: lui         $at, 0x906
    ctx->r1 = S32(0X906 << 16);
    // 0x800476F0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x800476F4: andi        $t9, $t8, 0xFFFF
    ctx->r25 = ctx->r24 & 0XFFFF;
    // 0x800476F8: or          $t0, $t9, $at
    ctx->r8 = ctx->r25 | ctx->r1;
    // 0x800476FC: sw          $t0, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r8;
    // 0x80047700: lh          $t5, 0x62($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X62);
    // 0x80047704: lh          $t2, 0x60($s0)
    ctx->r10 = MEM_H(ctx->r16, 0X60);
    // 0x80047708: lui         $at, 0x904
    ctx->r1 = S32(0X904 << 16);
    // 0x8004770C: andi        $t4, $t5, 0xFFFF
    ctx->r12 = ctx->r13 & 0XFFFF;
    // 0x80047710: sll         $t3, $t2, 16
    ctx->r11 = S32(ctx->r10 << 16);
    // 0x80047714: or          $t6, $t3, $t4
    ctx->r14 = ctx->r11 | ctx->r12;
    // 0x80047718: sw          $t6, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r14;
    // 0x8004771C: lh          $t7, 0x6E($s0)
    ctx->r15 = MEM_H(ctx->r16, 0X6E);
    // 0x80047720: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80047724: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x80047728: andi        $t8, $t7, 0xFFFF
    ctx->r24 = ctx->r15 & 0XFFFF;
    // 0x8004772C: or          $t9, $t8, $at
    ctx->r25 = ctx->r24 | ctx->r1;
    // 0x80047730: sw          $t9, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r25;
    // 0x80047734: lh          $t1, 0x6C($s0)
    ctx->r9 = MEM_H(ctx->r16, 0X6C);
    // 0x80047738: lhu         $t3, 0x6A($s0)
    ctx->r11 = MEM_HU(ctx->r16, 0X6A);
    // 0x8004773C: lui         $at, 0x301
    ctx->r1 = S32(0X301 << 16);
    // 0x80047740: sll         $t2, $t1, 16
    ctx->r10 = S32(ctx->r9 << 16);
    // 0x80047744: or          $t4, $t2, $t3
    ctx->r12 = ctx->r10 | ctx->r11;
    // 0x80047748: sw          $t4, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r12;
    // 0x8004774C: lh          $t6, 0x5E($s0)
    ctx->r14 = MEM_H(ctx->r16, 0X5E);
    // 0x80047750: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80047754: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x80047758: andi        $t7, $t6, 0xFFFF
    ctx->r15 = ctx->r14 & 0XFFFF;
    // 0x8004775C: or          $t8, $t7, $at
    ctx->r24 = ctx->r15 | ctx->r1;
    // 0x80047760: sw          $t8, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r24;
    // 0x80047764: lw          $a0, 0x54($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X54);
    // 0x80047768: sw          $v1, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r3;
    // 0x8004776C: jal         0x80059090
    // 0x80047770: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    osVirtualToPhysical_recomp(rdram, ctx);
        goto after_3;
    // 0x80047770: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    after_3:
    // 0x80047774: lw          $v1, 0x2C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X2C);
    // 0x80047778: b           L_8004779C
    // 0x8004777C: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
        goto L_8004779C;
    // 0x8004777C: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
L_80047780:
    // 0x80047780: sw          $t9, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r25;
    // 0x80047784: lw          $a0, 0x54($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X54);
    // 0x80047788: sw          $v1, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r3;
    // 0x8004778C: jal         0x80059090
    // 0x80047790: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    osVirtualToPhysical_recomp(rdram, ctx);
        goto after_4;
    // 0x80047790: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    after_4:
    // 0x80047794: lw          $v1, 0x28($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X28);
    // 0x80047798: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
L_8004779C:
    // 0x8004779C: lw          $v1, 0x4C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X4C);
    // 0x800477A0: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x800477A4: lh          $t0, 0x0($v1)
    ctx->r8 = MEM_H(ctx->r3, 0X0);
    // 0x800477A8: addiu       $t1, $t0, 0x170
    ctx->r9 = ADD32(ctx->r8, 0X170);
    // 0x800477AC: sh          $t1, 0x0($v1)
    MEM_H(0X0, ctx->r3) = ctx->r9;
    // 0x800477B0: lw          $t5, 0x70($s0)
    ctx->r13 = MEM_W(ctx->r16, 0X70);
    // 0x800477B4: addiu       $t2, $t5, 0xB8
    ctx->r10 = ADD32(ctx->r13, 0XB8);
    // 0x800477B8: sw          $t2, 0x70($s0)
    MEM_W(0X70, ctx->r16) = ctx->r10;
L_800477BC:
    // 0x800477BC: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
    // 0x800477C0: lw          $s0, 0x1C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X1C);
    // 0x800477C4: lw          $s1, 0x20($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X20);
    // 0x800477C8: jr          $ra
    // 0x800477CC: addiu       $sp, $sp, 0x48
    ctx->r29 = ADD32(ctx->r29, 0X48);
    return;
    // 0x800477CC: addiu       $sp, $sp, 0x48
    ctx->r29 = ADD32(ctx->r29, 0X48);
    // 0x800477D0: lw          $a0, 0x10($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X10);
    // 0x800477D4: lui         $at, 0x3FF0
    ctx->r1 = S32(0X3FF0 << 16);
    // 0x800477D8: lw          $t3, 0x14($sp)
    ctx->r11 = MEM_W(ctx->r29, 0X14);
    // 0x800477DC: bnel        $a0, $zero, L_80047814
    if (ctx->r4 != 0) {
        // 0x800477E0: mtc1        $at, $f19
        ctx->f_odd[(19 - 1) * 2] = ctx->r1;
            goto L_80047814;
    }
    goto skip_0;
    // 0x800477E0: mtc1        $at, $f19
    ctx->f_odd[(19 - 1) * 2] = ctx->r1;
    skip_0:
    // 0x800477E4: c.le.d      $f12, $f14
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 14);
    c1cs = ctx->f12.d <= ctx->f14.d;
    // 0x800477E8: ori         $t6, $zero, 0xFFFF
    ctx->r14 = 0 | 0XFFFF;
    // 0x800477EC: lw          $t7, 0x14($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X14);
    // 0x800477F0: lw          $t8, 0x14($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X14);
    // 0x800477F4: bc1f        L_80047808
    if (!c1cs) {
        // 0x800477F8: addiu       $v0, $zero, -0x8000
        ctx->r2 = ADD32(0, -0X8000);
            goto L_80047808;
    }
    // 0x800477F8: addiu       $v0, $zero, -0x8000
    ctx->r2 = ADD32(0, -0X8000);
    // 0x800477FC: sh          $t6, 0x0($t7)
    MEM_H(0X0, ctx->r15) = ctx->r14;
    // 0x80047800: jr          $ra
    // 0x80047804: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
    return;
    // 0x80047804: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
L_80047808:
    // 0x80047808: jr          $ra
    // 0x8004780C: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
    return;
    // 0x8004780C: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
    // 0x80047810: mtc1        $at, $f19
    ctx->f_odd[(19 - 1) * 2] = ctx->r1;
L_80047814:
    // 0x80047814: mtc1        $zero, $f18
    ctx->f18.u32l = 0;
    // 0x80047818: mtc1        $a0, $f4
    ctx->f4.u32l = ctx->r4;
    // 0x8004781C: mtc1        $zero, $f9
    ctx->f_odd[(9 - 1) * 2] = 0;
    // 0x80047820: c.lt.d      $f14, $f18
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 18);
    c1cs = ctx->f14.d < ctx->f18.d;
    // 0x80047824: mtc1        $zero, $f8
    ctx->f8.u32l = 0;
    // 0x80047828: cvt.d.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.d = CVT_D_W(ctx->f4.u32l);
    // 0x8004782C: bc1f        L_80047838
    if (!c1cs) {
        // 0x80047830: div.d       $f0, $f18, $f6
        CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f6.d); 
    ctx->f0.d = DIV_D(ctx->f18.d, ctx->f6.d);
            goto L_80047838;
    }
    // 0x80047830: div.d       $f0, $f18, $f6
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f6.d); 
    ctx->f0.d = DIV_D(ctx->f18.d, ctx->f6.d);
    // 0x80047834: mov.d       $f14, $f18
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 18);
    ctx->f14.d = ctx->f18.d;
L_80047838:
    // 0x80047838: c.le.d      $f12, $f8
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 8);
    c1cs = ctx->f12.d <= ctx->f8.d;
    // 0x8004783C: nop

    // 0x80047840: bc1fl       L_80047850
    if (!c1cs) {
        // 0x80047844: sub.d       $f10, $f14, $f12
        CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
            goto L_80047850;
    }
    goto skip_1;
    // 0x80047844: sub.d       $f10, $f14, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
    skip_1:
    // 0x80047848: mov.d       $f12, $f18
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 18);
    ctx->f12.d = ctx->f18.d;
    // 0x8004784C: sub.d       $f10, $f14, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
L_80047850:
    // 0x80047850: lui         $at, 0x4020
    ctx->r1 = S32(0X4020 << 16);
    // 0x80047854: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x80047858: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x8004785C: mul.d       $f4, $f10, $f0
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f10.d); NAN_CHECK(ctx->f0.d); 
    ctx->f4.d = MUL_D(ctx->f10.d, ctx->f0.d);
    // 0x80047860: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x80047864: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x80047868: mul.d       $f2, $f4, $f6
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.d); NAN_CHECK(ctx->f6.d); 
    ctx->f2.d = MUL_D(ctx->f4.d, ctx->f6.d);
    // 0x8004786C: trunc.w.d   $f8, $f2
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 2);
    ctx->f8.u32l = TRUNC_W_D(ctx->f2.d);
    // 0x80047870: mfc1        $v1, $f8
    ctx->r3 = (int32_t)ctx->f8.u32l;
    // 0x80047874: nop

    // 0x80047878: sll         $v1, $v1, 16
    ctx->r3 = S32(ctx->r3 << 16);
    // 0x8004787C: sra         $v1, $v1, 16
    ctx->r3 = S32(SIGNED(ctx->r3) >> 16);
    // 0x80047880: mtc1        $v1, $f10
    ctx->f10.u32l = ctx->r3;
    // 0x80047884: addiu       $t6, $v1, -0x1
    ctx->r14 = ADD32(ctx->r3, -0X1);
    // 0x80047888: cvt.d.w     $f4, $f10
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    ctx->f4.d = CVT_D_W(ctx->f10.u32l);
    // 0x8004788C: ldc1        $f10, -0x3338($at)
    CHECK_FR(ctx, 10);
    ctx->f10.u64 = LD(ctx->r1, -0X3338);
    // 0x80047890: lui         $at, 0x41E0
    ctx->r1 = S32(0X41E0 << 16);
    // 0x80047894: sub.d       $f6, $f2, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f2.d); NAN_CHECK(ctx->f4.d); 
    ctx->f6.d = ctx->f2.d - ctx->f4.d;
    // 0x80047898: add.d       $f16, $f6, $f18
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f6.d); NAN_CHECK(ctx->f18.d); 
    ctx->f16.d = ctx->f6.d + ctx->f18.d;
    // 0x8004789C: trunc.w.d   $f8, $f16
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 16);
    ctx->f8.u32l = TRUNC_W_D(ctx->f16.d);
    // 0x800478A0: mfc1        $a0, $f8
    ctx->r4 = (int32_t)ctx->f8.u32l;
    // 0x800478A4: nop

    // 0x800478A8: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x800478AC: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    // 0x800478B0: mtc1        $a0, $f4
    ctx->f4.u32l = ctx->r4;
    // 0x800478B4: addu        $v0, $t6, $a0
    ctx->r2 = ADD32(ctx->r14, ctx->r4);
    // 0x800478B8: sll         $v0, $v0, 16
    ctx->r2 = S32(ctx->r2 << 16);
    // 0x800478BC: cvt.d.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.d = CVT_D_W(ctx->f4.u32l);
    // 0x800478C0: sub.d       $f8, $f16, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f16.d); NAN_CHECK(ctx->f6.d); 
    ctx->f8.d = ctx->f16.d - ctx->f6.d;
    // 0x800478C4: mul.d       $f4, $f10, $f8
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f10.d); NAN_CHECK(ctx->f8.d); 
    ctx->f4.d = MUL_D(ctx->f10.d, ctx->f8.d);
    // 0x800478C8: cfc1        $t1, $FpcCsr
    ctx->r9 = get_cop1_cs();
    // 0x800478CC: ctc1        $t2, $FpcCsr
    set_cop1_cs(ctx->r10);
    // 0x800478D0: nop

    // 0x800478D4: cvt.w.d     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.u32l = CVT_W_D(ctx->f4.d);
    // 0x800478D8: cfc1        $t2, $FpcCsr
    ctx->r10 = get_cop1_cs();
    // 0x800478DC: nop

    // 0x800478E0: andi        $t2, $t2, 0x78
    ctx->r10 = ctx->r10 & 0X78;
    // 0x800478E4: beql        $t2, $zero, L_80047938
    if (ctx->r10 == 0) {
        // 0x800478E8: mfc1        $t2, $f6
        ctx->r10 = (int32_t)ctx->f6.u32l;
            goto L_80047938;
    }
    goto skip_2;
    // 0x800478E8: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
    skip_2:
    // 0x800478EC: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x800478F0: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x800478F4: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x800478F8: sub.d       $f6, $f4, $f6
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.d); NAN_CHECK(ctx->f6.d); 
    ctx->f6.d = ctx->f4.d - ctx->f6.d;
    // 0x800478FC: ctc1        $t2, $FpcCsr
    set_cop1_cs(ctx->r10);
    // 0x80047900: nop

    // 0x80047904: cvt.w.d     $f6, $f6
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 6);
    ctx->f6.u32l = CVT_W_D(ctx->f6.d);
    // 0x80047908: cfc1        $t2, $FpcCsr
    ctx->r10 = get_cop1_cs();
    // 0x8004790C: nop

    // 0x80047910: andi        $t2, $t2, 0x78
    ctx->r10 = ctx->r10 & 0X78;
    // 0x80047914: bne         $t2, $zero, L_8004792C
    if (ctx->r10 != 0) {
        // 0x80047918: nop
    
            goto L_8004792C;
    }
    // 0x80047918: nop

    // 0x8004791C: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
    // 0x80047920: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x80047924: b           L_80047944
    // 0x80047928: or          $t2, $t2, $at
    ctx->r10 = ctx->r10 | ctx->r1;
        goto L_80047944;
    // 0x80047928: or          $t2, $t2, $at
    ctx->r10 = ctx->r10 | ctx->r1;
L_8004792C:
    // 0x8004792C: b           L_80047944
    // 0x80047930: addiu       $t2, $zero, -0x1
    ctx->r10 = ADD32(0, -0X1);
        goto L_80047944;
    // 0x80047930: addiu       $t2, $zero, -0x1
    ctx->r10 = ADD32(0, -0X1);
    // 0x80047934: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
L_80047938:
    // 0x80047938: nop

    // 0x8004793C: bltz        $t2, L_8004792C
    if (SIGNED(ctx->r10) < 0) {
        // 0x80047940: nop
    
            goto L_8004792C;
    }
    // 0x80047940: nop

L_80047944:
    // 0x80047944: ctc1        $t1, $FpcCsr
    set_cop1_cs(ctx->r9);
    // 0x80047948: sh          $t2, 0x0($t3)
    MEM_H(0X0, ctx->r11) = ctx->r10;
    // 0x8004794C: sra         $v0, $v0, 16
    ctx->r2 = S32(SIGNED(ctx->r2) >> 16);
    // 0x80047950: jr          $ra
    // 0x80047954: nop

    return;
    // 0x80047954: nop

;}
RECOMP_FUNC void static_5_80047958(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80047958: sw          $a0, 0x0($sp)
    MEM_W(0X0, ctx->r29) = ctx->r4;
    // 0x8004795C: sw          $a2, 0x8($sp)
    MEM_W(0X8, ctx->r29) = ctx->r6;
    // 0x80047960: sll         $a2, $a2, 16
    ctx->r6 = S32(ctx->r6 << 16);
    // 0x80047964: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x80047968: sw          $a3, 0xC($sp)
    MEM_W(0XC, ctx->r29) = ctx->r7;
    // 0x8004796C: sra         $a1, $a1, 3
    ctx->r5 = S32(SIGNED(ctx->r5) >> 3);
    // 0x80047970: andi        $a3, $a3, 0xFFFF
    ctx->r7 = ctx->r7 & 0XFFFF;
    // 0x80047974: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    // 0x80047978: bne         $a1, $zero, L_80047988
    if (ctx->r5 != 0) {
        // 0x8004797C: sra         $a2, $a2, 16
        ctx->r6 = S32(SIGNED(ctx->r6) >> 16);
            goto L_80047988;
    }
    // 0x8004797C: sra         $a2, $a2, 16
    ctx->r6 = S32(SIGNED(ctx->r6) >> 16);
    // 0x80047980: jr          $ra
    // 0x80047984: or          $v0, $a0, $zero
    ctx->r2 = ctx->r4 | 0;
    return;
    // 0x80047984: or          $v0, $a0, $zero
    ctx->r2 = ctx->r4 | 0;
L_80047988:
    // 0x80047988: multu       $a3, $a1
    result = U64(U32(ctx->r7)) * U64(U32(ctx->r5)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x8004798C: mflo        $t6
    ctx->r14 = lo;
    // 0x80047990: sra         $t7, $t6, 16
    ctx->r15 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80047994: nop

    // 0x80047998: multu       $a2, $a1
    result = U64(U32(ctx->r6)) * U64(U32(ctx->r5)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x8004799C: mflo        $t8
    ctx->r24 = lo;
    // 0x800479A0: addu        $t9, $t7, $t8
    ctx->r25 = ADD32(ctx->r15, ctx->r24);
    // 0x800479A4: addu        $a0, $a0, $t9
    ctx->r4 = ADD32(ctx->r4, ctx->r25);
    // 0x800479A8: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x800479AC: sra         $v0, $a0, 16
    ctx->r2 = S32(SIGNED(ctx->r4) >> 16);
    // 0x800479B0: jr          $ra
    // 0x800479B4: nop

    return;
    // 0x800479B4: nop

    // 0x800479B8: nop

    // 0x800479BC: nop

;}
RECOMP_FUNC void static_5_800490CC(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x800490CC: lui         $v0, 0x8008
    ctx->r2 = S32(0X8008 << 16);
    // 0x800490D0: lw          $v0, -0x7A7C($v0)
    ctx->r2 = MEM_W(ctx->r2, -0X7A7C);
    // 0x800490D4: addiu       $sp, $sp, -0x28
    ctx->r29 = ADD32(ctx->r29, -0X28);
    // 0x800490D8: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x800490DC: sw          $a1, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r5;
    // 0x800490E0: lw          $a2, 0x14($v0)
    ctx->r6 = MEM_W(ctx->r2, 0X14);
    // 0x800490E4: sll         $a1, $a1, 16
    ctx->r5 = S32(ctx->r5 << 16);
    // 0x800490E8: sra         $a1, $a1, 16
    ctx->r5 = S32(SIGNED(ctx->r5) >> 16);
    // 0x800490EC: or          $a3, $a0, $zero
    ctx->r7 = ctx->r4 | 0;
    // 0x800490F0: beq         $a2, $zero, L_80049128
    if (ctx->r6 == 0) {
        // 0x800490F4: or          $v1, $zero, $zero
        ctx->r3 = 0 | 0;
            goto L_80049128;
    }
    // 0x800490F4: or          $v1, $zero, $zero
    ctx->r3 = 0 | 0;
    // 0x800490F8: sw          $a2, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r6;
    // 0x800490FC: sw          $a2, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r6;
    // 0x80049100: sw          $zero, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = 0;
    // 0x80049104: jal         0x80056F50
    // 0x80049108: or          $a0, $a2, $zero
    ctx->r4 = ctx->r6 | 0;
    alUnlink(rdram, ctx);
        goto after_0;
    // 0x80049108: or          $a0, $a2, $zero
    ctx->r4 = ctx->r6 | 0;
    after_0:
    // 0x8004910C: lui         $a1, 0x8008
    ctx->r5 = S32(0X8008 << 16);
    // 0x80049110: lw          $a1, -0x7A7C($a1)
    ctx->r5 = MEM_W(ctx->r5, -0X7A7C);
    // 0x80049114: lw          $a0, 0x24($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X24);
    // 0x80049118: jal         0x80056F80
    // 0x8004911C: addiu       $a1, $a1, 0xC
    ctx->r5 = ADD32(ctx->r5, 0XC);
    alLink(rdram, ctx);
        goto after_1;
    // 0x8004911C: addiu       $a1, $a1, 0xC
    ctx->r5 = ADD32(ctx->r5, 0XC);
    after_1:
    // 0x80049120: b           L_800491A8
    // 0x80049124: lw          $v1, 0x1C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X1C);
        goto L_800491A8;
    // 0x80049124: lw          $v1, 0x1C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X1C);
L_80049128:
    // 0x80049128: lw          $a2, 0x4($v0)
    ctx->r6 = MEM_W(ctx->r2, 0X4);
    // 0x8004912C: beq         $a2, $zero, L_80049160
    if (ctx->r6 == 0) {
        // 0x80049130: or          $a0, $a2, $zero
        ctx->r4 = ctx->r6 | 0;
            goto L_80049160;
    }
    // 0x80049130: or          $a0, $a2, $zero
    ctx->r4 = ctx->r6 | 0;
    // 0x80049134: sw          $a2, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r6;
    // 0x80049138: sw          $a2, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r6;
    // 0x8004913C: jal         0x80056F50
    // 0x80049140: sw          $v1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r3;
    alUnlink(rdram, ctx);
        goto after_2;
    // 0x80049140: sw          $v1, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r3;
    after_2:
    // 0x80049144: lui         $a1, 0x8008
    ctx->r5 = S32(0X8008 << 16);
    // 0x80049148: lw          $a1, -0x7A7C($a1)
    ctx->r5 = MEM_W(ctx->r5, -0X7A7C);
    // 0x8004914C: lw          $a0, 0x24($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X24);
    // 0x80049150: jal         0x80056F80
    // 0x80049154: addiu       $a1, $a1, 0xC
    ctx->r5 = ADD32(ctx->r5, 0XC);
    alLink(rdram, ctx);
        goto after_3;
    // 0x80049154: addiu       $a1, $a1, 0xC
    ctx->r5 = ADD32(ctx->r5, 0XC);
    after_3:
    // 0x80049158: b           L_800491A8
    // 0x8004915C: lw          $v1, 0x1C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X1C);
        goto L_800491A8;
    // 0x8004915C: lw          $v1, 0x1C($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X1C);
L_80049160:
    // 0x80049160: lw          $a2, 0xC($v0)
    ctx->r6 = MEM_W(ctx->r2, 0XC);
    // 0x80049164: beql        $a2, $zero, L_800491AC
    if (ctx->r6 == 0) {
        // 0x80049168: lw          $ra, 0x14($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X14);
            goto L_800491AC;
    }
    goto skip_0;
    // 0x80049168: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    skip_0:
    // 0x8004916C: lw          $t6, 0x8($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X8);
L_80049170:
    // 0x80049170: lh          $t7, 0x16($t6)
    ctx->r15 = MEM_H(ctx->r14, 0X16);
    // 0x80049174: slt         $at, $a1, $t7
    ctx->r1 = SIGNED(ctx->r5) < SIGNED(ctx->r15) ? 1 : 0;
    // 0x80049178: bnel        $at, $zero, L_800491A0
    if (ctx->r1 != 0) {
        // 0x8004917C: lw          $a2, 0x0($a2)
        ctx->r6 = MEM_W(ctx->r6, 0X0);
            goto L_800491A0;
    }
    goto skip_1;
    // 0x8004917C: lw          $a2, 0x0($a2)
    ctx->r6 = MEM_W(ctx->r6, 0X0);
    skip_1:
    // 0x80049180: lw          $t8, 0x88($a2)
    ctx->r24 = MEM_W(ctx->r6, 0X88);
    // 0x80049184: bnel        $t8, $zero, L_800491A0
    if (ctx->r24 != 0) {
        // 0x80049188: lw          $a2, 0x0($a2)
        ctx->r6 = MEM_W(ctx->r6, 0X0);
            goto L_800491A0;
    }
    goto skip_2;
    // 0x80049188: lw          $a2, 0x0($a2)
    ctx->r6 = MEM_W(ctx->r6, 0X0);
    skip_2:
    // 0x8004918C: sw          $a2, 0x0($a3)
    MEM_W(0X0, ctx->r7) = ctx->r6;
    // 0x80049190: lw          $t9, 0x8($a2)
    ctx->r25 = MEM_W(ctx->r6, 0X8);
    // 0x80049194: addiu       $v1, $zero, 0x1
    ctx->r3 = ADD32(0, 0X1);
    // 0x80049198: lh          $a1, 0x16($t9)
    ctx->r5 = MEM_H(ctx->r25, 0X16);
    // 0x8004919C: lw          $a2, 0x0($a2)
    ctx->r6 = MEM_W(ctx->r6, 0X0);
L_800491A0:
    // 0x800491A0: bnel        $a2, $zero, L_80049170
    if (ctx->r6 != 0) {
        // 0x800491A4: lw          $t6, 0x8($a2)
        ctx->r14 = MEM_W(ctx->r6, 0X8);
            goto L_80049170;
    }
    goto skip_3;
    // 0x800491A4: lw          $t6, 0x8($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X8);
    skip_3:
L_800491A8:
    // 0x800491A8: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_800491AC:
    // 0x800491AC: addiu       $sp, $sp, 0x28
    ctx->r29 = ADD32(ctx->r29, 0X28);
    // 0x800491B0: or          $v0, $v1, $zero
    ctx->r2 = ctx->r3 | 0;
    // 0x800491B4: jr          $ra
    // 0x800491B8: nop

    return;
    // 0x800491B8: nop

    // 0x800491BC: nop

;}
RECOMP_FUNC void static_5_800496E0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x800496E0: lui         $t6, 0x8008
    ctx->r14 = S32(0X8008 << 16);
    // 0x800496E4: lw          $t6, -0x7A7C($t6)
    ctx->r14 = MEM_W(ctx->r14, -0X7A7C);
    // 0x800496E8: mtc1        $a0, $f4
    ctx->f4.u32l = ctx->r4;
    // 0x800496EC: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x800496F0: lw          $t7, 0x40($t6)
    ctx->r15 = MEM_W(ctx->r14, 0X40);
    // 0x800496F4: cvt.s.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
    // 0x800496F8: ldc1        $f4, -0x2B40($at)
    CHECK_FR(ctx, 4);
    ctx->f4.u64 = LD(ctx->r1, -0X2B40);
    // 0x800496FC: mtc1        $t7, $f8
    ctx->f8.u32l = ctx->r15;
    // 0x80049700: lui         $at, 0x3FE0
    ctx->r1 = S32(0X3FE0 << 16);
    // 0x80049704: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x80049708: cvt.s.w     $f10, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    ctx->f10.fl = CVT_S_W(ctx->f8.u32l);
    // 0x8004970C: mul.s       $f16, $f6, $f10
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f16.fl = MUL_S(ctx->f6.fl, ctx->f10.fl);
    // 0x80049710: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x80049714: cvt.d.s     $f18, $f16
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f16.fl); 
    ctx->f18.d = CVT_D_S(ctx->f16.fl);
    // 0x80049718: div.d       $f8, $f18, $f4
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f4.d); 
    ctx->f8.d = DIV_D(ctx->f18.d, ctx->f4.d);
    // 0x8004971C: add.d       $f10, $f8, $f6
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f8.d); NAN_CHECK(ctx->f6.d); 
    ctx->f10.d = ctx->f8.d + ctx->f6.d;
    // 0x80049720: cvt.s.d     $f0, $f10
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f10.d); 
    ctx->f0.fl = CVT_S_D(ctx->f10.d);
    // 0x80049724: trunc.w.s   $f16, $f0
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 0);
    ctx->f16.u32l = TRUNC_W_S(ctx->f0.fl);
    // 0x80049728: mfc1        $v0, $f16
    ctx->r2 = (int32_t)ctx->f16.u32l;
    // 0x8004972C: jr          $ra
    // 0x80049730: nop

    return;
    // 0x80049730: nop

;}
RECOMP_FUNC void static_5_8004FB1C(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8004FB1C: addiu       $sp, $sp, -0x20
    ctx->r29 = ADD32(ctx->r29, -0X20);
    // 0x8004FB20: sw          $s1, 0x18($sp)
    MEM_W(0X18, ctx->r29) = ctx->r17;
    // 0x8004FB24: sw          $s0, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r16;
    // 0x8004FB28: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x8004FB2C: or          $s1, $a1, $zero
    ctx->r17 = ctx->r5 | 0;
    // 0x8004FB30: sw          $ra, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r31;
    // 0x8004FB34: blez        $a3, L_8004FBA4
    if (SIGNED(ctx->r7) <= 0) {
        // 0x8004FB38: sw          $a2, 0x28($sp)
        MEM_W(0X28, ctx->r29) = ctx->r6;
            goto L_8004FBA4;
    }
    // 0x8004FB38: sw          $a2, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r6;
    // 0x8004FB3C: lw          $a0, 0x3C($a1)
    ctx->r4 = MEM_W(ctx->r5, 0X3C);
    // 0x8004FB40: lw          $a2, 0x2C($s1)
    ctx->r6 = MEM_W(ctx->r17, 0X2C);
    // 0x8004FB44: sw          $a3, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r7;
    // 0x8004FB48: lw          $t9, 0x28($s1)
    ctx->r25 = MEM_W(ctx->r17, 0X28);
    // 0x8004FB4C: or          $a1, $a3, $zero
    ctx->r5 = ctx->r7 | 0;
    // 0x8004FB50: jalr        $t9
    // 0x8004FB54: nop

    LOOKUP_FUNC(ctx->r25)(rdram, ctx);
        goto after_0;
    // 0x8004FB54: nop

    after_0:
    // 0x8004FB58: lw          $a3, 0x2C($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X2C);
    // 0x8004FB5C: andi        $a1, $v0, 0x7
    ctx->r5 = ctx->r2 & 0X7;
    // 0x8004FB60: lh          $t3, 0x36($sp)
    ctx->r11 = MEM_H(ctx->r29, 0X36);
    // 0x8004FB64: addu        $a3, $a3, $a1
    ctx->r7 = ADD32(ctx->r7, ctx->r5);
    // 0x8004FB68: andi        $t6, $a3, 0x7
    ctx->r14 = ctx->r7 & 0X7;
    // 0x8004FB6C: subu        $t7, $a3, $t6
    ctx->r15 = SUB32(ctx->r7, ctx->r14);
    // 0x8004FB70: addiu       $t8, $t7, 0x8
    ctx->r24 = ADD32(ctx->r15, 0X8);
    // 0x8004FB74: andi        $t0, $t8, 0xFFF
    ctx->r8 = ctx->r24 & 0XFFF;
    // 0x8004FB78: sll         $t1, $t0, 12
    ctx->r9 = S32(ctx->r8 << 12);
    // 0x8004FB7C: lui         $at, 0x400
    ctx->r1 = S32(0X400 << 16);
    // 0x8004FB80: or          $t2, $t1, $at
    ctx->r10 = ctx->r9 | ctx->r1;
    // 0x8004FB84: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8004FB88: andi        $t4, $t3, 0xFFF
    ctx->r12 = ctx->r11 & 0XFFF;
    // 0x8004FB8C: or          $t5, $t2, $t4
    ctx->r13 = ctx->r10 | ctx->r12;
    // 0x8004FB90: subu        $t9, $v0, $a1
    ctx->r25 = SUB32(ctx->r2, ctx->r5);
    // 0x8004FB94: sw          $t9, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r25;
    // 0x8004FB98: sw          $t5, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r13;
    // 0x8004FB9C: b           L_8004FBA8
    // 0x8004FBA0: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
        goto L_8004FBA8;
    // 0x8004FBA0: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
L_8004FBA4:
    // 0x8004FBA4: or          $a1, $zero, $zero
    ctx->r5 = 0 | 0;
L_8004FBA8:
    // 0x8004FBA8: lw          $a0, 0x38($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X38);
    // 0x8004FBAC: or          $v0, $s0, $zero
    ctx->r2 = ctx->r16 | 0;
    // 0x8004FBB0: lui         $t7, 0xF00
    ctx->r15 = S32(0XF00 << 16);
    // 0x8004FBB4: andi        $t6, $a0, 0x2
    ctx->r14 = ctx->r4 & 0X2;
    // 0x8004FBB8: beq         $t6, $zero, L_8004FBDC
    if (ctx->r14 == 0) {
        // 0x8004FBBC: sll         $t9, $a0, 28
        ctx->r25 = S32(ctx->r4 << 28);
            goto L_8004FBDC;
    }
    // 0x8004FBBC: sll         $t9, $a0, 28
    ctx->r25 = S32(ctx->r4 << 28);
    // 0x8004FBC0: sw          $t7, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r15;
    // 0x8004FBC4: lw          $t8, 0x10($s1)
    ctx->r24 = MEM_W(ctx->r17, 0X10);
    // 0x8004FBC8: lui         $at, 0x1FFF
    ctx->r1 = S32(0X1FFF << 16);
    // 0x8004FBCC: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x8004FBD0: and         $t0, $t8, $at
    ctx->r8 = ctx->r24 & ctx->r1;
    // 0x8004FBD4: sw          $t0, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r8;
    // 0x8004FBD8: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
L_8004FBDC:
    // 0x8004FBDC: lw          $t1, 0xC($s1)
    ctx->r9 = MEM_W(ctx->r17, 0XC);
    // 0x8004FBE0: lui         $at, 0x1FFF
    ctx->r1 = S32(0X1FFF << 16);
    // 0x8004FBE4: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x8004FBE8: and         $t3, $t1, $at
    ctx->r11 = ctx->r9 & ctx->r1;
    // 0x8004FBEC: lui         $at, 0xFF
    ctx->r1 = S32(0XFF << 16);
    // 0x8004FBF0: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x8004FBF4: and         $t2, $t3, $at
    ctx->r10 = ctx->r11 & ctx->r1;
    // 0x8004FBF8: lui         $at, 0x100
    ctx->r1 = S32(0X100 << 16);
    // 0x8004FBFC: or          $t4, $t2, $at
    ctx->r12 = ctx->r10 | ctx->r1;
    // 0x8004FC00: or          $v1, $s0, $zero
    ctx->r3 = ctx->r16 | 0;
    // 0x8004FC04: sw          $t4, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r12;
    // 0x8004FC08: lw          $t6, 0x28($sp)
    ctx->r14 = MEM_W(ctx->r29, 0X28);
    // 0x8004FC0C: lh          $t5, 0x32($sp)
    ctx->r13 = MEM_H(ctx->r29, 0X32);
    // 0x8004FC10: andi        $t3, $a1, 0xF
    ctx->r11 = ctx->r5 & 0XF;
    // 0x8004FC14: sll         $t7, $t6, 1
    ctx->r15 = S32(ctx->r14 << 1);
    // 0x8004FC18: andi        $t8, $t7, 0xFFF
    ctx->r24 = ctx->r15 & 0XFFF;
    // 0x8004FC1C: sll         $t0, $t8, 16
    ctx->r8 = S32(ctx->r24 << 16);
    // 0x8004FC20: or          $t1, $t9, $t0
    ctx->r9 = ctx->r25 | ctx->r8;
    // 0x8004FC24: sll         $t2, $t3, 12
    ctx->r10 = S32(ctx->r11 << 12);
    // 0x8004FC28: or          $t4, $t1, $t2
    ctx->r12 = ctx->r9 | ctx->r10;
    // 0x8004FC2C: andi        $t6, $t5, 0xFFF
    ctx->r14 = ctx->r13 & 0XFFF;
    // 0x8004FC30: or          $t7, $t4, $t6
    ctx->r15 = ctx->r12 | ctx->r14;
    // 0x8004FC34: sw          $t7, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r15;
    // 0x8004FC38: sw          $zero, 0x38($s1)
    MEM_W(0X38, ctx->r17) = 0;
    // 0x8004FC3C: lw          $ra, 0x1C($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X1C);
    // 0x8004FC40: addiu       $v0, $s0, 0x8
    ctx->r2 = ADD32(ctx->r16, 0X8);
    // 0x8004FC44: lw          $s0, 0x14($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X14);
    // 0x8004FC48: lw          $s1, 0x18($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X18);
    // 0x8004FC4C: jr          $ra
    // 0x8004FC50: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    return;
    // 0x8004FC50: addiu       $sp, $sp, 0x20
    ctx->r29 = ADD32(ctx->r29, 0X20);
    // 0x8004FC54: nop

    // 0x8004FC58: nop

    // 0x8004FC5C: nop

;}
RECOMP_FUNC void static_5_80058080(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80058080: lbu         $t6, 0x3($a0)
    ctx->r14 = MEM_BU(ctx->r4, 0X3);
    // 0x80058084: bne         $t6, $zero, L_80058164
    if (ctx->r14 != 0) {
        // 0x80058088: nop
    
            goto L_80058164;
    }
    // 0x80058088: nop

    // 0x8005808C: lh          $t7, 0xE($a0)
    ctx->r15 = MEM_H(ctx->r4, 0XE);
    // 0x80058090: addiu       $t1, $zero, 0x1
    ctx->r9 = ADD32(0, 0X1);
    // 0x80058094: sb          $t1, 0x3($a0)
    MEM_B(0X3, ctx->r4) = ctx->r9;
    // 0x80058098: blez        $t7, L_80058164
    if (SIGNED(ctx->r15) <= 0) {
        // 0x8005809C: or          $v0, $zero, $zero
        ctx->r2 = 0 | 0;
            goto L_80058164;
    }
    // 0x8005809C: or          $v0, $zero, $zero
    ctx->r2 = 0 | 0;
    // 0x800580A0: or          $v1, $a0, $zero
    ctx->r3 = ctx->r4 | 0;
    // 0x800580A4: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x800580A8: lw          $t8, 0x10($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X10);
L_800580AC:
    // 0x800580AC: addu        $t9, $t8, $a1
    ctx->r25 = ADD32(ctx->r24, ctx->r5);
    // 0x800580B0: sw          $t9, 0x10($v1)
    MEM_W(0X10, ctx->r3) = ctx->r25;
    // 0x800580B4: lbu         $t6, 0xE($t9)
    ctx->r14 = MEM_BU(ctx->r25, 0XE);
    // 0x800580B8: or          $a2, $t9, $zero
    ctx->r6 = ctx->r25 | 0;
    // 0x800580BC: bnel        $t6, $zero, L_80058150
    if (ctx->r14 != 0) {
        // 0x800580C0: lh          $t8, 0xE($a0)
        ctx->r24 = MEM_H(ctx->r4, 0XE);
            goto L_80058150;
    }
    goto skip_0;
    // 0x800580C0: lh          $t8, 0xE($a0)
    ctx->r24 = MEM_H(ctx->r4, 0XE);
    skip_0:
    // 0x800580C4: lw          $t7, 0x0($t9)
    ctx->r15 = MEM_W(ctx->r25, 0X0);
    // 0x800580C8: sb          $t1, 0xE($t9)
    MEM_B(0XE, ctx->r25) = ctx->r9;
    // 0x800580CC: addu        $t8, $t7, $a1
    ctx->r24 = ADD32(ctx->r15, ctx->r5);
    // 0x800580D0: sw          $t8, 0x0($t9)
    MEM_W(0X0, ctx->r25) = ctx->r24;
    // 0x800580D4: lw          $t9, 0x4($t9)
    ctx->r25 = MEM_W(ctx->r25, 0X4);
    // 0x800580D8: lw          $t7, 0x8($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X8);
    // 0x800580DC: addu        $t6, $t9, $a1
    ctx->r14 = ADD32(ctx->r25, ctx->r5);
    // 0x800580E0: addu        $t8, $t7, $a1
    ctx->r24 = ADD32(ctx->r15, ctx->r5);
    // 0x800580E4: sw          $t6, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r14;
    // 0x800580E8: sw          $t8, 0x8($a2)
    MEM_W(0X8, ctx->r6) = ctx->r24;
    // 0x800580EC: lbu         $t9, 0x9($t8)
    ctx->r25 = MEM_BU(ctx->r24, 0X9);
    // 0x800580F0: or          $t0, $t8, $zero
    ctx->r8 = ctx->r24 | 0;
    // 0x800580F4: bnel        $t9, $zero, L_80058150
    if (ctx->r25 != 0) {
        // 0x800580F8: lh          $t8, 0xE($a0)
        ctx->r24 = MEM_H(ctx->r4, 0XE);
            goto L_80058150;
    }
    goto skip_1;
    // 0x800580F8: lh          $t8, 0xE($a0)
    ctx->r24 = MEM_H(ctx->r4, 0XE);
    skip_1:
    // 0x800580FC: lw          $t6, 0x0($t8)
    ctx->r14 = MEM_W(ctx->r24, 0X0);
    // 0x80058100: lbu         $a2, 0x8($t8)
    ctx->r6 = MEM_BU(ctx->r24, 0X8);
    // 0x80058104: sb          $t1, 0x9($t8)
    MEM_B(0X9, ctx->r24) = ctx->r9;
    // 0x80058108: addu        $t7, $t6, $a3
    ctx->r15 = ADD32(ctx->r14, ctx->r7);
    // 0x8005810C: bne         $a2, $zero, L_80058134
    if (ctx->r6 != 0) {
        // 0x80058110: sw          $t7, 0x0($t8)
        MEM_W(0X0, ctx->r24) = ctx->r15;
            goto L_80058134;
    }
    // 0x80058110: sw          $t7, 0x0($t8)
    MEM_W(0X0, ctx->r24) = ctx->r15;
    // 0x80058114: lw          $t8, 0x10($t8)
    ctx->r24 = MEM_W(ctx->r24, 0X10);
    // 0x80058118: lw          $a2, 0xC($t0)
    ctx->r6 = MEM_W(ctx->r8, 0XC);
    // 0x8005811C: addu        $t9, $t8, $a1
    ctx->r25 = ADD32(ctx->r24, ctx->r5);
    // 0x80058120: beq         $a2, $zero, L_8005814C
    if (ctx->r6 == 0) {
        // 0x80058124: sw          $t9, 0x10($t0)
        MEM_W(0X10, ctx->r8) = ctx->r25;
            goto L_8005814C;
    }
    // 0x80058124: sw          $t9, 0x10($t0)
    MEM_W(0X10, ctx->r8) = ctx->r25;
    // 0x80058128: addu        $t6, $a2, $a1
    ctx->r14 = ADD32(ctx->r6, ctx->r5);
    // 0x8005812C: b           L_8005814C
    // 0x80058130: sw          $t6, 0xC($t0)
    MEM_W(0XC, ctx->r8) = ctx->r14;
        goto L_8005814C;
    // 0x80058130: sw          $t6, 0xC($t0)
    MEM_W(0XC, ctx->r8) = ctx->r14;
L_80058134:
    // 0x80058134: bnel        $t2, $a2, L_80058150
    if (ctx->r10 != ctx->r6) {
        // 0x80058138: lh          $t8, 0xE($a0)
        ctx->r24 = MEM_H(ctx->r4, 0XE);
            goto L_80058150;
    }
    goto skip_2;
    // 0x80058138: lh          $t8, 0xE($a0)
    ctx->r24 = MEM_H(ctx->r4, 0XE);
    skip_2:
    // 0x8005813C: lw          $a2, 0xC($t0)
    ctx->r6 = MEM_W(ctx->r8, 0XC);
    // 0x80058140: beq         $a2, $zero, L_8005814C
    if (ctx->r6 == 0) {
        // 0x80058144: addu        $t7, $a2, $a1
        ctx->r15 = ADD32(ctx->r6, ctx->r5);
            goto L_8005814C;
    }
    // 0x80058144: addu        $t7, $a2, $a1
    ctx->r15 = ADD32(ctx->r6, ctx->r5);
    // 0x80058148: sw          $t7, 0xC($t0)
    MEM_W(0XC, ctx->r8) = ctx->r15;
L_8005814C:
    // 0x8005814C: lh          $t8, 0xE($a0)
    ctx->r24 = MEM_H(ctx->r4, 0XE);
L_80058150:
    // 0x80058150: addiu       $v0, $v0, 0x1
    ctx->r2 = ADD32(ctx->r2, 0X1);
    // 0x80058154: addiu       $v1, $v1, 0x4
    ctx->r3 = ADD32(ctx->r3, 0X4);
    // 0x80058158: slt         $at, $v0, $t8
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r24) ? 1 : 0;
    // 0x8005815C: bnel        $at, $zero, L_800580AC
    if (ctx->r1 != 0) {
        // 0x80058160: lw          $t8, 0x10($v1)
        ctx->r24 = MEM_W(ctx->r3, 0X10);
            goto L_800580AC;
    }
    goto skip_3;
    // 0x80058160: lw          $t8, 0x10($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X10);
    skip_3:
L_80058164:
    // 0x80058164: jr          $ra
    // 0x80058168: nop

    return;
    // 0x80058168: nop

    // 0x8005816C: jr          $ra
    // 0x80058170: nop

    return;
    // 0x80058170: nop

;}
RECOMP_FUNC void static_5_8005D1E0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8005D1E0: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x8005D1E4: sw          $a1, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r5;
    // 0x8005D1E8: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x8005D1EC: andi        $t6, $a1, 0xFF
    ctx->r14 = ctx->r5 & 0XFF;
    // 0x8005D1F0: slti        $at, $t6, 0x26
    ctx->r1 = SIGNED(ctx->r14) < 0X26 ? 1 : 0;
    // 0x8005D1F4: or          $a1, $t6, $zero
    ctx->r5 = ctx->r14 | 0;
    // 0x8005D1F8: sw          $zero, 0xC($s0)
    MEM_W(0XC, ctx->r16) = 0;
    // 0x8005D1FC: sw          $zero, 0x10($s0)
    MEM_W(0X10, ctx->r16) = 0;
    // 0x8005D200: sw          $zero, 0x14($s0)
    MEM_W(0X14, ctx->r16) = 0;
    // 0x8005D204: sw          $zero, 0x18($s0)
    MEM_W(0X18, ctx->r16) = 0;
    // 0x8005D208: sw          $zero, 0x1C($s0)
    MEM_W(0X1C, ctx->r16) = 0;
    // 0x8005D20C: sw          $zero, 0x20($s0)
    MEM_W(0X20, ctx->r16) = 0;
    // 0x8005D210: bne         $at, $zero, L_8005D23C
    if (ctx->r1 != 0) {
        // 0x8005D214: or          $v1, $t6, $zero
        ctx->r3 = ctx->r14 | 0;
            goto L_8005D23C;
    }
    // 0x8005D214: or          $v1, $t6, $zero
    ctx->r3 = ctx->r14 | 0;
    // 0x8005D218: addiu       $t7, $t6, -0x45
    ctx->r15 = ADD32(ctx->r14, -0X45);
    // 0x8005D21C: sltiu       $at, $t7, 0x34
    ctx->r1 = ctx->r15 < 0X34 ? 1 : 0;
    // 0x8005D220: beq         $at, $zero, L_8005D828
    if (ctx->r1 == 0) {
        // 0x8005D224: sll         $t7, $t7, 2
        ctx->r15 = S32(ctx->r15 << 2);
            goto L_8005D828;
    }
    // 0x8005D224: sll         $t7, $t7, 2
    ctx->r15 = S32(ctx->r15 << 2);
    // 0x8005D228: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x8005D22C: addu        $at, $at, $t7
    gpr jr_addend_8005D234 = ctx->r15;
    ctx->r1 = ADD32(ctx->r1, ctx->r15);
    // 0x8005D230: lw          $t7, -0x1C4C($at)
    ctx->r15 = ADD32(ctx->r1, -0X1C4C);
    // 0x8005D234: jr          $t7
    // 0x8005D238: nop

    switch (jr_addend_8005D234 >> 2) {
        case 0: goto L_8005D548; break;
        case 1: goto L_8005D828; break;
        case 2: goto L_8005D548; break;
        case 3: goto L_8005D828; break;
        case 4: goto L_8005D828; break;
        case 5: goto L_8005D828; break;
        case 6: goto L_8005D828; break;
        case 7: goto L_8005D828; break;
        case 8: goto L_8005D828; break;
        case 9: goto L_8005D828; break;
        case 10: goto L_8005D828; break;
        case 11: goto L_8005D828; break;
        case 12: goto L_8005D828; break;
        case 13: goto L_8005D828; break;
        case 14: goto L_8005D828; break;
        case 15: goto L_8005D828; break;
        case 16: goto L_8005D828; break;
        case 17: goto L_8005D828; break;
        case 18: goto L_8005D828; break;
        case 19: goto L_8005D3F8; break;
        case 20: goto L_8005D828; break;
        case 21: goto L_8005D828; break;
        case 22: goto L_8005D828; break;
        case 23: goto L_8005D828; break;
        case 24: goto L_8005D828; break;
        case 25: goto L_8005D828; break;
        case 26: goto L_8005D828; break;
        case 27: goto L_8005D828; break;
        case 28: goto L_8005D828; break;
        case 29: goto L_8005D828; break;
        case 30: goto L_8005D250; break;
        case 31: goto L_8005D288; break;
        case 32: goto L_8005D548; break;
        case 33: goto L_8005D548; break;
        case 34: goto L_8005D548; break;
        case 35: goto L_8005D828; break;
        case 36: goto L_8005D288; break;
        case 37: goto L_8005D828; break;
        case 38: goto L_8005D828; break;
        case 39: goto L_8005D828; break;
        case 40: goto L_8005D828; break;
        case 41: goto L_8005D6AC; break;
        case 42: goto L_8005D3F8; break;
        case 43: goto L_8005D77C; break;
        case 44: goto L_8005D828; break;
        case 45: goto L_8005D828; break;
        case 46: goto L_8005D7C4; break;
        case 47: goto L_8005D828; break;
        case 48: goto L_8005D3F8; break;
        case 49: goto L_8005D828; break;
        case 50: goto L_8005D828; break;
        case 51: goto L_8005D3F8; break;
        default: switch_error(__func__, 0x8005D234, 0x8007E3B4);
    }
    // 0x8005D238: nop

L_8005D23C:
    // 0x8005D23C: addiu       $at, $zero, 0x25
    ctx->r1 = ADD32(0, 0X25);
    // 0x8005D240: beql        $v1, $at, L_8005D80C
    if (ctx->r3 == ctx->r1) {
        // 0x8005D244: lw          $t8, 0xC($s0)
        ctx->r24 = MEM_W(ctx->r16, 0XC);
            goto L_8005D80C;
    }
    goto skip_0;
    // 0x8005D244: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    skip_0:
    // 0x8005D248: b           L_8005D82C
    // 0x8005D24C: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
        goto L_8005D82C;
    // 0x8005D24C: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
L_8005D250:
    // 0x8005D250: lw          $t8, 0x0($a2)
    ctx->r24 = MEM_W(ctx->r6, 0X0);
    // 0x8005D254: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D258: addiu       $t9, $t8, 0x3
    ctx->r25 = ADD32(ctx->r24, 0X3);
    // 0x8005D25C: and         $t6, $t9, $at
    ctx->r14 = ctx->r25 & ctx->r1;
    // 0x8005D260: addiu       $t7, $t6, 0x4
    ctx->r15 = ADD32(ctx->r14, 0X4);
    // 0x8005D264: sw          $t7, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r15;
    // 0x8005D268: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D26C: lw          $t9, -0x4($t7)
    ctx->r25 = MEM_W(ctx->r15, -0X4);
    // 0x8005D270: addu        $t7, $a3, $t6
    ctx->r15 = ADD32(ctx->r7, ctx->r14);
    // 0x8005D274: sb          $t9, 0x0($t7)
    MEM_B(0X0, ctx->r15) = ctx->r25;
    // 0x8005D278: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    // 0x8005D27C: addiu       $t6, $t8, 0x1
    ctx->r14 = ADD32(ctx->r24, 0X1);
    // 0x8005D280: b           L_8005D840
    // 0x8005D284: sw          $t6, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r14;
        goto L_8005D840;
    // 0x8005D284: sw          $t6, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r14;
L_8005D288:
    // 0x8005D288: lbu         $v0, 0x34($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D28C: addiu       $at, $zero, 0x6C
    ctx->r1 = ADD32(0, 0X6C);
    // 0x8005D290: bnel        $v0, $at, L_8005D2C8
    if (ctx->r2 != ctx->r1) {
        // 0x8005D294: addiu       $at, $zero, 0x4C
        ctx->r1 = ADD32(0, 0X4C);
            goto L_8005D2C8;
    }
    goto skip_1;
    // 0x8005D294: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
    skip_1:
    // 0x8005D298: lw          $t9, 0x0($a2)
    ctx->r25 = MEM_W(ctx->r6, 0X0);
    // 0x8005D29C: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D2A0: addiu       $t7, $t9, 0x3
    ctx->r15 = ADD32(ctx->r25, 0X3);
    // 0x8005D2A4: and         $t8, $t7, $at
    ctx->r24 = ctx->r15 & ctx->r1;
    // 0x8005D2A8: addiu       $t6, $t8, 0x4
    ctx->r14 = ADD32(ctx->r24, 0X4);
    // 0x8005D2AC: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D2B0: lw          $t7, -0x4($t6)
    ctx->r15 = MEM_W(ctx->r14, -0X4);
    // 0x8005D2B4: sra         $t8, $t7, 31
    ctx->r24 = S32(SIGNED(ctx->r15) >> 31);
    // 0x8005D2B8: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D2BC: b           L_8005D324
    // 0x8005D2C0: sw          $t7, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r15;
        goto L_8005D324;
    // 0x8005D2C0: sw          $t7, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r15;
    // 0x8005D2C4: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
L_8005D2C8:
    // 0x8005D2C8: bnel        $v0, $at, L_8005D300
    if (ctx->r2 != ctx->r1) {
        // 0x8005D2CC: lw          $t7, 0x0($a2)
        ctx->r15 = MEM_W(ctx->r6, 0X0);
            goto L_8005D300;
    }
    goto skip_2;
    // 0x8005D2CC: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
    skip_2:
    // 0x8005D2D0: lw          $t6, 0x0($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X0);
    // 0x8005D2D4: addiu       $at, $zero, -0x8
    ctx->r1 = ADD32(0, -0X8);
    // 0x8005D2D8: addiu       $t7, $t6, 0x7
    ctx->r15 = ADD32(ctx->r14, 0X7);
    // 0x8005D2DC: and         $t8, $t7, $at
    ctx->r24 = ctx->r15 & ctx->r1;
    // 0x8005D2E0: addiu       $t9, $t8, 0x8
    ctx->r25 = ADD32(ctx->r24, 0X8);
    // 0x8005D2E4: sw          $t9, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r25;
    // 0x8005D2E8: lw          $t8, -0x8($t9)
    ctx->r24 = MEM_W(ctx->r25, -0X8);
    // 0x8005D2EC: lw          $t9, -0x4($t9)
    ctx->r25 = MEM_W(ctx->r25, -0X4);
    // 0x8005D2F0: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D2F4: b           L_8005D324
    // 0x8005D2F8: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
        goto L_8005D324;
    // 0x8005D2F8: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
    // 0x8005D2FC: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
L_8005D300:
    // 0x8005D300: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D304: addiu       $t6, $t7, 0x3
    ctx->r14 = ADD32(ctx->r15, 0X3);
    // 0x8005D308: and         $t8, $t6, $at
    ctx->r24 = ctx->r14 & ctx->r1;
    // 0x8005D30C: addiu       $t9, $t8, 0x4
    ctx->r25 = ADD32(ctx->r24, 0X4);
    // 0x8005D310: sw          $t9, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r25;
    // 0x8005D314: lw          $t6, -0x4($t9)
    ctx->r14 = MEM_W(ctx->r25, -0X4);
    // 0x8005D318: sra         $t8, $t6, 31
    ctx->r24 = S32(SIGNED(ctx->r14) >> 31);
    // 0x8005D31C: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D320: sw          $t6, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r14;
L_8005D324:
    // 0x8005D324: lbu         $t7, 0x34($s0)
    ctx->r15 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D328: addiu       $at, $zero, 0x68
    ctx->r1 = ADD32(0, 0X68);
    // 0x8005D32C: bnel        $t7, $at, L_8005D350
    if (ctx->r15 != ctx->r1) {
        // 0x8005D330: lw          $t6, 0x0($s0)
        ctx->r14 = MEM_W(ctx->r16, 0X0);
            goto L_8005D350;
    }
    goto skip_3;
    // 0x8005D330: lw          $t6, 0x0($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X0);
    skip_3:
    // 0x8005D334: lw          $t7, 0x4($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X4);
    // 0x8005D338: sll         $t9, $t7, 16
    ctx->r25 = S32(ctx->r15 << 16);
    // 0x8005D33C: sra         $t6, $t9, 16
    ctx->r14 = S32(SIGNED(ctx->r25) >> 16);
    // 0x8005D340: sra         $t8, $t6, 31
    ctx->r24 = S32(SIGNED(ctx->r14) >> 31);
    // 0x8005D344: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D348: sw          $t6, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r14;
    // 0x8005D34C: lw          $t6, 0x0($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X0);
L_8005D350:
    // 0x8005D350: bgtzl       $t6, L_8005D38C
    if (SIGNED(ctx->r14) > 0) {
        // 0x8005D354: lw          $v0, 0x30($s0)
        ctx->r2 = MEM_W(ctx->r16, 0X30);
            goto L_8005D38C;
    }
    goto skip_4;
    // 0x8005D354: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
    skip_4:
    // 0x8005D358: bltzl       $t6, L_8005D36C
    if (SIGNED(ctx->r14) < 0) {
        // 0x8005D35C: lw          $t9, 0xC($s0)
        ctx->r25 = MEM_W(ctx->r16, 0XC);
            goto L_8005D36C;
    }
    goto skip_5;
    // 0x8005D35C: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
    skip_5:
    // 0x8005D360: b           L_8005D38C
    // 0x8005D364: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
        goto L_8005D38C;
    // 0x8005D364: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
    // 0x8005D368: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
L_8005D36C:
    // 0x8005D36C: addiu       $t8, $zero, 0x2D
    ctx->r24 = ADD32(0, 0X2D);
    // 0x8005D370: addu        $t6, $a3, $t9
    ctx->r14 = ADD32(ctx->r7, ctx->r25);
    // 0x8005D374: sb          $t8, 0x0($t6)
    MEM_B(0X0, ctx->r14) = ctx->r24;
    // 0x8005D378: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D37C: addiu       $t9, $t7, 0x1
    ctx->r25 = ADD32(ctx->r15, 0X1);
    // 0x8005D380: b           L_8005D3DC
    // 0x8005D384: sw          $t9, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r25;
        goto L_8005D3DC;
    // 0x8005D384: sw          $t9, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r25;
    // 0x8005D388: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
L_8005D38C:
    // 0x8005D38C: andi        $t8, $v0, 0x2
    ctx->r24 = ctx->r2 & 0X2;
    // 0x8005D390: beq         $t8, $zero, L_8005D3B8
    if (ctx->r24 == 0) {
        // 0x8005D394: andi        $t6, $v0, 0x1
        ctx->r14 = ctx->r2 & 0X1;
            goto L_8005D3B8;
    }
    // 0x8005D394: andi        $t6, $v0, 0x1
    ctx->r14 = ctx->r2 & 0X1;
    // 0x8005D398: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D39C: addiu       $t6, $zero, 0x2B
    ctx->r14 = ADD32(0, 0X2B);
    // 0x8005D3A0: addu        $t9, $a3, $t7
    ctx->r25 = ADD32(ctx->r7, ctx->r15);
    // 0x8005D3A4: sb          $t6, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r14;
    // 0x8005D3A8: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    // 0x8005D3AC: addiu       $t7, $t8, 0x1
    ctx->r15 = ADD32(ctx->r24, 0X1);
    // 0x8005D3B0: b           L_8005D3DC
    // 0x8005D3B4: sw          $t7, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r15;
        goto L_8005D3DC;
    // 0x8005D3B4: sw          $t7, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r15;
L_8005D3B8:
    // 0x8005D3B8: beql        $t6, $zero, L_8005D3E0
    if (ctx->r14 == 0) {
        // 0x8005D3BC: lw          $t9, 0xC($s0)
        ctx->r25 = MEM_W(ctx->r16, 0XC);
            goto L_8005D3E0;
    }
    goto skip_6;
    // 0x8005D3BC: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
    skip_6:
    // 0x8005D3C0: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    // 0x8005D3C4: addiu       $t9, $zero, 0x20
    ctx->r25 = ADD32(0, 0X20);
    // 0x8005D3C8: addu        $t7, $a3, $t8
    ctx->r15 = ADD32(ctx->r7, ctx->r24);
    // 0x8005D3CC: sb          $t9, 0x0($t7)
    MEM_B(0X0, ctx->r15) = ctx->r25;
    // 0x8005D3D0: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D3D4: addiu       $t8, $t6, 0x1
    ctx->r24 = ADD32(ctx->r14, 0X1);
    // 0x8005D3D8: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
L_8005D3DC:
    // 0x8005D3DC: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
L_8005D3E0:
    // 0x8005D3E0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8005D3E4: addu        $t7, $t9, $a3
    ctx->r15 = ADD32(ctx->r25, ctx->r7);
    // 0x8005D3E8: jal         0x80064CA0
    // 0x8005D3EC: sw          $t7, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r15;
    _Litob(rdram, ctx);
        goto after_0;
    // 0x8005D3EC: sw          $t7, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r15;
    after_0:
    // 0x8005D3F0: b           L_8005D844
    // 0x8005D3F4: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
        goto L_8005D844;
    // 0x8005D3F4: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_8005D3F8:
    // 0x8005D3F8: lbu         $v0, 0x34($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D3FC: addiu       $at, $zero, 0x6C
    ctx->r1 = ADD32(0, 0X6C);
    // 0x8005D400: bnel        $v0, $at, L_8005D438
    if (ctx->r2 != ctx->r1) {
        // 0x8005D404: addiu       $at, $zero, 0x4C
        ctx->r1 = ADD32(0, 0X4C);
            goto L_8005D438;
    }
    goto skip_7;
    // 0x8005D404: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
    skip_7:
    // 0x8005D408: lw          $t6, 0x0($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X0);
    // 0x8005D40C: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D410: addiu       $t8, $t6, 0x3
    ctx->r24 = ADD32(ctx->r14, 0X3);
    // 0x8005D414: and         $t9, $t8, $at
    ctx->r25 = ctx->r24 & ctx->r1;
    // 0x8005D418: addiu       $t7, $t9, 0x4
    ctx->r15 = ADD32(ctx->r25, 0X4);
    // 0x8005D41C: sw          $t7, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r15;
    // 0x8005D420: lw          $t8, -0x4($t7)
    ctx->r24 = MEM_W(ctx->r15, -0X4);
    // 0x8005D424: sra         $t6, $t8, 31
    ctx->r14 = S32(SIGNED(ctx->r24) >> 31);
    // 0x8005D428: sw          $t6, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r14;
    // 0x8005D42C: b           L_8005D494
    // 0x8005D430: sw          $t8, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r24;
        goto L_8005D494;
    // 0x8005D430: sw          $t8, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r24;
    // 0x8005D434: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
L_8005D438:
    // 0x8005D438: bnel        $v0, $at, L_8005D470
    if (ctx->r2 != ctx->r1) {
        // 0x8005D43C: lw          $t6, 0x0($a2)
        ctx->r14 = MEM_W(ctx->r6, 0X0);
            goto L_8005D470;
    }
    goto skip_8;
    // 0x8005D43C: lw          $t6, 0x0($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X0);
    skip_8:
    // 0x8005D440: lw          $t9, 0x0($a2)
    ctx->r25 = MEM_W(ctx->r6, 0X0);
    // 0x8005D444: addiu       $at, $zero, -0x8
    ctx->r1 = ADD32(0, -0X8);
    // 0x8005D448: addiu       $t8, $t9, 0x7
    ctx->r24 = ADD32(ctx->r25, 0X7);
    // 0x8005D44C: and         $t6, $t8, $at
    ctx->r14 = ctx->r24 & ctx->r1;
    // 0x8005D450: addiu       $t7, $t6, 0x8
    ctx->r15 = ADD32(ctx->r14, 0X8);
    // 0x8005D454: sw          $t7, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r15;
    // 0x8005D458: lw          $t9, -0x4($t7)
    ctx->r25 = MEM_W(ctx->r15, -0X4);
    // 0x8005D45C: lw          $t8, -0x8($t7)
    ctx->r24 = MEM_W(ctx->r15, -0X8);
    // 0x8005D460: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
    // 0x8005D464: b           L_8005D494
    // 0x8005D468: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
        goto L_8005D494;
    // 0x8005D468: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D46C: lw          $t6, 0x0($a2)
    ctx->r14 = MEM_W(ctx->r6, 0X0);
L_8005D470:
    // 0x8005D470: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D474: addiu       $t7, $t6, 0x3
    ctx->r15 = ADD32(ctx->r14, 0X3);
    // 0x8005D478: and         $t8, $t7, $at
    ctx->r24 = ctx->r15 & ctx->r1;
    // 0x8005D47C: addiu       $t9, $t8, 0x4
    ctx->r25 = ADD32(ctx->r24, 0X4);
    // 0x8005D480: sw          $t9, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r25;
    // 0x8005D484: lw          $t7, -0x4($t9)
    ctx->r15 = MEM_W(ctx->r25, -0X4);
    // 0x8005D488: sra         $t8, $t7, 31
    ctx->r24 = S32(SIGNED(ctx->r15) >> 31);
    // 0x8005D48C: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D490: sw          $t7, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r15;
L_8005D494:
    // 0x8005D494: lbu         $v0, 0x34($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D498: addiu       $at, $zero, 0x68
    ctx->r1 = ADD32(0, 0X68);
    // 0x8005D49C: bne         $v0, $at, L_8005D4BC
    if (ctx->r2 != ctx->r1) {
        // 0x8005D4A0: nop
    
            goto L_8005D4BC;
    }
    // 0x8005D4A0: nop

    // 0x8005D4A4: lw          $t7, 0x4($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X4);
    // 0x8005D4A8: addiu       $t6, $zero, 0x0
    ctx->r14 = ADD32(0, 0X0);
    // 0x8005D4AC: sw          $t6, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r14;
    // 0x8005D4B0: andi        $t9, $t7, 0xFFFF
    ctx->r25 = ctx->r15 & 0XFFFF;
    // 0x8005D4B4: b           L_8005D4D4
    // 0x8005D4B8: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
        goto L_8005D4D4;
    // 0x8005D4B8: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
L_8005D4BC:
    // 0x8005D4BC: bnel        $v0, $zero, L_8005D4D8
    if (ctx->r2 != 0) {
        // 0x8005D4C0: lw          $t7, 0x30($s0)
        ctx->r15 = MEM_W(ctx->r16, 0X30);
            goto L_8005D4D8;
    }
    goto skip_9;
    // 0x8005D4C0: lw          $t7, 0x30($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X30);
    skip_9:
    // 0x8005D4C4: lw          $t9, 0x4($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X4);
    // 0x8005D4C8: addiu       $t8, $zero, 0x0
    ctx->r24 = ADD32(0, 0X0);
    // 0x8005D4CC: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D4D0: sw          $t9, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r25;
L_8005D4D4:
    // 0x8005D4D4: lw          $t7, 0x30($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X30);
L_8005D4D8:
    // 0x8005D4D8: andi        $t6, $t7, 0x8
    ctx->r14 = ctx->r15 & 0X8;
    // 0x8005D4DC: beql        $t6, $zero, L_8005D530
    if (ctx->r14 == 0) {
        // 0x8005D4E0: lw          $t8, 0xC($s0)
        ctx->r24 = MEM_W(ctx->r16, 0XC);
            goto L_8005D530;
    }
    goto skip_10;
    // 0x8005D4E0: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    skip_10:
    // 0x8005D4E4: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
    // 0x8005D4E8: addiu       $t8, $zero, 0x30
    ctx->r24 = ADD32(0, 0X30);
    // 0x8005D4EC: addiu       $at, $zero, 0x78
    ctx->r1 = ADD32(0, 0X78);
    // 0x8005D4F0: addu        $t7, $a3, $t9
    ctx->r15 = ADD32(ctx->r7, ctx->r25);
    // 0x8005D4F4: sb          $t8, 0x0($t7)
    MEM_B(0X0, ctx->r15) = ctx->r24;
    // 0x8005D4F8: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D4FC: addiu       $t9, $t6, 0x1
    ctx->r25 = ADD32(ctx->r14, 0X1);
    // 0x8005D500: beq         $v1, $at, L_8005D514
    if (ctx->r3 == ctx->r1) {
        // 0x8005D504: sw          $t9, 0xC($s0)
        MEM_W(0XC, ctx->r16) = ctx->r25;
            goto L_8005D514;
    }
    // 0x8005D504: sw          $t9, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r25;
    // 0x8005D508: addiu       $at, $zero, 0x58
    ctx->r1 = ADD32(0, 0X58);
    // 0x8005D50C: bnel        $v1, $at, L_8005D530
    if (ctx->r3 != ctx->r1) {
        // 0x8005D510: lw          $t8, 0xC($s0)
        ctx->r24 = MEM_W(ctx->r16, 0XC);
            goto L_8005D530;
    }
    goto skip_11;
    // 0x8005D510: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    skip_11:
L_8005D514:
    // 0x8005D514: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    // 0x8005D518: addu        $t7, $a3, $t8
    ctx->r15 = ADD32(ctx->r7, ctx->r24);
    // 0x8005D51C: sb          $a1, 0x0($t7)
    MEM_B(0X0, ctx->r15) = ctx->r5;
    // 0x8005D520: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D524: addiu       $t9, $t6, 0x1
    ctx->r25 = ADD32(ctx->r14, 0X1);
    // 0x8005D528: sw          $t9, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r25;
    // 0x8005D52C: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
L_8005D530:
    // 0x8005D530: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8005D534: addu        $t7, $t8, $a3
    ctx->r15 = ADD32(ctx->r24, ctx->r7);
    // 0x8005D538: jal         0x80064CA0
    // 0x8005D53C: sw          $t7, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r15;
    _Litob(rdram, ctx);
        goto after_1;
    // 0x8005D53C: sw          $t7, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r15;
    after_1:
    // 0x8005D540: b           L_8005D844
    // 0x8005D544: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
        goto L_8005D844;
    // 0x8005D544: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_8005D548:
    // 0x8005D548: lbu         $t6, 0x34($s0)
    ctx->r14 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D54C: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
    // 0x8005D550: bnel        $t6, $at, L_8005D5B8
    if (ctx->r14 != ctx->r1) {
        // 0x8005D554: lw          $v0, 0x0($a2)
        ctx->r2 = MEM_W(ctx->r6, 0X0);
            goto L_8005D5B8;
    }
    goto skip_12;
    // 0x8005D554: lw          $v0, 0x0($a2)
    ctx->r2 = MEM_W(ctx->r6, 0X0);
    skip_12:
    // 0x8005D558: lw          $v0, 0x0($a2)
    ctx->r2 = MEM_W(ctx->r6, 0X0);
    // 0x8005D55C: andi        $t9, $v0, 0x1
    ctx->r25 = ctx->r2 & 0X1;
    // 0x8005D560: beq         $t9, $zero, L_8005D578
    if (ctx->r25 == 0) {
        // 0x8005D564: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_8005D578;
    }
    // 0x8005D564: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x8005D568: addiu       $t8, $v1, 0x7
    ctx->r24 = ADD32(ctx->r3, 0X7);
    // 0x8005D56C: sw          $t8, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r24;
    // 0x8005D570: b           L_8005D5A8
    // 0x8005D574: addiu       $v0, $t8, -0x16
    ctx->r2 = ADD32(ctx->r24, -0X16);
        goto L_8005D5A8;
    // 0x8005D574: addiu       $v0, $t8, -0x16
    ctx->r2 = ADD32(ctx->r24, -0X16);
L_8005D578:
    // 0x8005D578: andi        $t7, $v1, 0x2
    ctx->r15 = ctx->r3 & 0X2;
    // 0x8005D57C: beq         $t7, $zero, L_8005D594
    if (ctx->r15 == 0) {
        // 0x8005D580: addiu       $t9, $v0, 0x7
        ctx->r25 = ADD32(ctx->r2, 0X7);
            goto L_8005D594;
    }
    // 0x8005D580: addiu       $t9, $v0, 0x7
    ctx->r25 = ADD32(ctx->r2, 0X7);
    // 0x8005D584: addiu       $t6, $v1, 0xA
    ctx->r14 = ADD32(ctx->r3, 0XA);
    // 0x8005D588: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D58C: b           L_8005D5A4
    // 0x8005D590: addiu       $a0, $t6, -0x28
    ctx->r4 = ADD32(ctx->r14, -0X28);
        goto L_8005D5A4;
    // 0x8005D590: addiu       $a0, $t6, -0x28
    ctx->r4 = ADD32(ctx->r14, -0X28);
L_8005D594:
    // 0x8005D594: addiu       $at, $zero, -0x8
    ctx->r1 = ADD32(0, -0X8);
    // 0x8005D598: and         $t8, $t9, $at
    ctx->r24 = ctx->r25 & ctx->r1;
    // 0x8005D59C: addiu       $a0, $t8, 0x8
    ctx->r4 = ADD32(ctx->r24, 0X8);
    // 0x8005D5A0: sw          $a0, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r4;
L_8005D5A4:
    // 0x8005D5A4: or          $v0, $a0, $zero
    ctx->r2 = ctx->r4 | 0;
L_8005D5A8:
    // 0x8005D5A8: ldc1        $f4, -0x8($v0)
    CHECK_FR(ctx, 4);
    ctx->f4.u64 = LD(ctx->r2, -0X8);
    // 0x8005D5AC: b           L_8005D60C
    // 0x8005D5B0: sdc1        $f4, 0x0($s0)
    CHECK_FR(ctx, 4);
    SD(ctx->f4.u64, 0X0, ctx->r16);
        goto L_8005D60C;
    // 0x8005D5B0: sdc1        $f4, 0x0($s0)
    CHECK_FR(ctx, 4);
    SD(ctx->f4.u64, 0X0, ctx->r16);
    // 0x8005D5B4: lw          $v0, 0x0($a2)
    ctx->r2 = MEM_W(ctx->r6, 0X0);
L_8005D5B8:
    // 0x8005D5B8: andi        $t6, $v0, 0x1
    ctx->r14 = ctx->r2 & 0X1;
    // 0x8005D5BC: beq         $t6, $zero, L_8005D5D4
    if (ctx->r14 == 0) {
        // 0x8005D5C0: or          $v1, $v0, $zero
        ctx->r3 = ctx->r2 | 0;
            goto L_8005D5D4;
    }
    // 0x8005D5C0: or          $v1, $v0, $zero
    ctx->r3 = ctx->r2 | 0;
    // 0x8005D5C4: addiu       $t9, $v1, 0x7
    ctx->r25 = ADD32(ctx->r3, 0X7);
    // 0x8005D5C8: sw          $t9, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r25;
    // 0x8005D5CC: b           L_8005D604
    // 0x8005D5D0: addiu       $v0, $t9, -0x16
    ctx->r2 = ADD32(ctx->r25, -0X16);
        goto L_8005D604;
    // 0x8005D5D0: addiu       $v0, $t9, -0x16
    ctx->r2 = ADD32(ctx->r25, -0X16);
L_8005D5D4:
    // 0x8005D5D4: andi        $t8, $v1, 0x2
    ctx->r24 = ctx->r3 & 0X2;
    // 0x8005D5D8: beq         $t8, $zero, L_8005D5F0
    if (ctx->r24 == 0) {
        // 0x8005D5DC: addiu       $t6, $v0, 0x7
        ctx->r14 = ADD32(ctx->r2, 0X7);
            goto L_8005D5F0;
    }
    // 0x8005D5DC: addiu       $t6, $v0, 0x7
    ctx->r14 = ADD32(ctx->r2, 0X7);
    // 0x8005D5E0: addiu       $t7, $v1, 0xA
    ctx->r15 = ADD32(ctx->r3, 0XA);
    // 0x8005D5E4: sw          $t7, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r15;
    // 0x8005D5E8: b           L_8005D600
    // 0x8005D5EC: addiu       $a0, $t7, -0x28
    ctx->r4 = ADD32(ctx->r15, -0X28);
        goto L_8005D600;
    // 0x8005D5EC: addiu       $a0, $t7, -0x28
    ctx->r4 = ADD32(ctx->r15, -0X28);
L_8005D5F0:
    // 0x8005D5F0: addiu       $at, $zero, -0x8
    ctx->r1 = ADD32(0, -0X8);
    // 0x8005D5F4: and         $t9, $t6, $at
    ctx->r25 = ctx->r14 & ctx->r1;
    // 0x8005D5F8: addiu       $a0, $t9, 0x8
    ctx->r4 = ADD32(ctx->r25, 0X8);
    // 0x8005D5FC: sw          $a0, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r4;
L_8005D600:
    // 0x8005D600: or          $v0, $a0, $zero
    ctx->r2 = ctx->r4 | 0;
L_8005D604:
    // 0x8005D604: ldc1        $f6, -0x8($v0)
    CHECK_FR(ctx, 6);
    ctx->f6.u64 = LD(ctx->r2, -0X8);
    // 0x8005D608: sdc1        $f6, 0x0($s0)
    CHECK_FR(ctx, 6);
    SD(ctx->f6.u64, 0X0, ctx->r16);
L_8005D60C:
    // 0x8005D60C: lhu         $t7, 0x0($s0)
    ctx->r15 = MEM_HU(ctx->r16, 0X0);
    // 0x8005D610: andi        $t6, $t7, 0x8000
    ctx->r14 = ctx->r15 & 0X8000;
    // 0x8005D614: beql        $t6, $zero, L_8005D640
    if (ctx->r14 == 0) {
        // 0x8005D618: lw          $v0, 0x30($s0)
        ctx->r2 = MEM_W(ctx->r16, 0X30);
            goto L_8005D640;
    }
    goto skip_13;
    // 0x8005D618: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
    skip_13:
    // 0x8005D61C: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    // 0x8005D620: addiu       $t9, $zero, 0x2D
    ctx->r25 = ADD32(0, 0X2D);
    // 0x8005D624: addu        $t7, $a3, $t8
    ctx->r15 = ADD32(ctx->r7, ctx->r24);
    // 0x8005D628: sb          $t9, 0x0($t7)
    MEM_B(0X0, ctx->r15) = ctx->r25;
    // 0x8005D62C: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D630: addiu       $t8, $t6, 0x1
    ctx->r24 = ADD32(ctx->r14, 0X1);
    // 0x8005D634: b           L_8005D690
    // 0x8005D638: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
        goto L_8005D690;
    // 0x8005D638: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
    // 0x8005D63C: lw          $v0, 0x30($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X30);
L_8005D640:
    // 0x8005D640: andi        $t9, $v0, 0x2
    ctx->r25 = ctx->r2 & 0X2;
    // 0x8005D644: beq         $t9, $zero, L_8005D66C
    if (ctx->r25 == 0) {
        // 0x8005D648: andi        $t7, $v0, 0x1
        ctx->r15 = ctx->r2 & 0X1;
            goto L_8005D66C;
    }
    // 0x8005D648: andi        $t7, $v0, 0x1
    ctx->r15 = ctx->r2 & 0X1;
    // 0x8005D64C: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
    // 0x8005D650: addiu       $t7, $zero, 0x2B
    ctx->r15 = ADD32(0, 0X2B);
    // 0x8005D654: addu        $t8, $a3, $t6
    ctx->r24 = ADD32(ctx->r7, ctx->r14);
    // 0x8005D658: sb          $t7, 0x0($t8)
    MEM_B(0X0, ctx->r24) = ctx->r15;
    // 0x8005D65C: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
    // 0x8005D660: addiu       $t6, $t9, 0x1
    ctx->r14 = ADD32(ctx->r25, 0X1);
    // 0x8005D664: b           L_8005D690
    // 0x8005D668: sw          $t6, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r14;
        goto L_8005D690;
    // 0x8005D668: sw          $t6, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r14;
L_8005D66C:
    // 0x8005D66C: beql        $t7, $zero, L_8005D694
    if (ctx->r15 == 0) {
        // 0x8005D670: lw          $t8, 0xC($s0)
        ctx->r24 = MEM_W(ctx->r16, 0XC);
            goto L_8005D694;
    }
    goto skip_14;
    // 0x8005D670: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
    skip_14:
    // 0x8005D674: lw          $t9, 0xC($s0)
    ctx->r25 = MEM_W(ctx->r16, 0XC);
    // 0x8005D678: addiu       $t8, $zero, 0x20
    ctx->r24 = ADD32(0, 0X20);
    // 0x8005D67C: addu        $t6, $a3, $t9
    ctx->r14 = ADD32(ctx->r7, ctx->r25);
    // 0x8005D680: sb          $t8, 0x0($t6)
    MEM_B(0X0, ctx->r14) = ctx->r24;
    // 0x8005D684: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D688: addiu       $t9, $t7, 0x1
    ctx->r25 = ADD32(ctx->r15, 0X1);
    // 0x8005D68C: sw          $t9, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r25;
L_8005D690:
    // 0x8005D690: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
L_8005D694:
    // 0x8005D694: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8005D698: addu        $t6, $t8, $a3
    ctx->r14 = ADD32(ctx->r24, ctx->r7);
    // 0x8005D69C: jal         0x800645C0
    // 0x8005D6A0: sw          $t6, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r14;
    _Ldtob(rdram, ctx);
        goto after_2;
    // 0x8005D6A0: sw          $t6, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r14;
    after_2:
    // 0x8005D6A4: b           L_8005D844
    // 0x8005D6A8: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
        goto L_8005D844;
    // 0x8005D6A8: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_8005D6AC:
    // 0x8005D6AC: lbu         $v0, 0x34($s0)
    ctx->r2 = MEM_BU(ctx->r16, 0X34);
    // 0x8005D6B0: addiu       $at, $zero, 0x68
    ctx->r1 = ADD32(0, 0X68);
    // 0x8005D6B4: bnel        $v0, $at, L_8005D6E8
    if (ctx->r2 != ctx->r1) {
        // 0x8005D6B8: addiu       $at, $zero, 0x6C
        ctx->r1 = ADD32(0, 0X6C);
            goto L_8005D6E8;
    }
    goto skip_15;
    // 0x8005D6B8: addiu       $at, $zero, 0x6C
    ctx->r1 = ADD32(0, 0X6C);
    skip_15:
    // 0x8005D6BC: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
    // 0x8005D6C0: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D6C4: addiu       $t9, $t7, 0x3
    ctx->r25 = ADD32(ctx->r15, 0X3);
    // 0x8005D6C8: and         $t8, $t9, $at
    ctx->r24 = ctx->r25 & ctx->r1;
    // 0x8005D6CC: addiu       $t6, $t8, 0x4
    ctx->r14 = ADD32(ctx->r24, 0X4);
    // 0x8005D6D0: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D6D4: lw          $t9, -0x4($t6)
    ctx->r25 = MEM_W(ctx->r14, -0X4);
    // 0x8005D6D8: lw          $t7, 0x2C($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X2C);
    // 0x8005D6DC: b           L_8005D840
    // 0x8005D6E0: sh          $t7, 0x0($t9)
    MEM_H(0X0, ctx->r25) = ctx->r15;
        goto L_8005D840;
    // 0x8005D6E0: sh          $t7, 0x0($t9)
    MEM_H(0X0, ctx->r25) = ctx->r15;
    // 0x8005D6E4: addiu       $at, $zero, 0x6C
    ctx->r1 = ADD32(0, 0X6C);
L_8005D6E8:
    // 0x8005D6E8: bnel        $v0, $at, L_8005D71C
    if (ctx->r2 != ctx->r1) {
        // 0x8005D6EC: addiu       $at, $zero, 0x4C
        ctx->r1 = ADD32(0, 0X4C);
            goto L_8005D71C;
    }
    goto skip_16;
    // 0x8005D6EC: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
    skip_16:
    // 0x8005D6F0: lw          $t8, 0x0($a2)
    ctx->r24 = MEM_W(ctx->r6, 0X0);
    // 0x8005D6F4: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D6F8: addiu       $t6, $t8, 0x3
    ctx->r14 = ADD32(ctx->r24, 0X3);
    // 0x8005D6FC: and         $t7, $t6, $at
    ctx->r15 = ctx->r14 & ctx->r1;
    // 0x8005D700: addiu       $t9, $t7, 0x4
    ctx->r25 = ADD32(ctx->r15, 0X4);
    // 0x8005D704: sw          $t9, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r25;
    // 0x8005D708: lw          $t6, -0x4($t9)
    ctx->r14 = MEM_W(ctx->r25, -0X4);
    // 0x8005D70C: lw          $t8, 0x2C($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X2C);
    // 0x8005D710: b           L_8005D840
    // 0x8005D714: sw          $t8, 0x0($t6)
    MEM_W(0X0, ctx->r14) = ctx->r24;
        goto L_8005D840;
    // 0x8005D714: sw          $t8, 0x0($t6)
    MEM_W(0X0, ctx->r14) = ctx->r24;
    // 0x8005D718: addiu       $at, $zero, 0x4C
    ctx->r1 = ADD32(0, 0X4C);
L_8005D71C:
    // 0x8005D71C: bnel        $v0, $at, L_8005D758
    if (ctx->r2 != ctx->r1) {
        // 0x8005D720: lw          $t7, 0x0($a2)
        ctx->r15 = MEM_W(ctx->r6, 0X0);
            goto L_8005D758;
    }
    goto skip_17;
    // 0x8005D720: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
    skip_17:
    // 0x8005D724: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
    // 0x8005D728: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D72C: addiu       $t9, $t7, 0x3
    ctx->r25 = ADD32(ctx->r15, 0X3);
    // 0x8005D730: and         $t8, $t9, $at
    ctx->r24 = ctx->r25 & ctx->r1;
    // 0x8005D734: addiu       $t6, $t8, 0x4
    ctx->r14 = ADD32(ctx->r24, 0X4);
    // 0x8005D738: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D73C: lw          $t6, -0x4($t6)
    ctx->r14 = MEM_W(ctx->r14, -0X4);
    // 0x8005D740: lw          $t7, 0x2C($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X2C);
    // 0x8005D744: addiu       $t8, $zero, 0x0
    ctx->r24 = ADD32(0, 0X0);
    // 0x8005D748: sw          $t8, 0x0($t6)
    MEM_W(0X0, ctx->r14) = ctx->r24;
    // 0x8005D74C: b           L_8005D840
    // 0x8005D750: sw          $t7, 0x4($t6)
    MEM_W(0X4, ctx->r14) = ctx->r15;
        goto L_8005D840;
    // 0x8005D750: sw          $t7, 0x4($t6)
    MEM_W(0X4, ctx->r14) = ctx->r15;
    // 0x8005D754: lw          $t7, 0x0($a2)
    ctx->r15 = MEM_W(ctx->r6, 0X0);
L_8005D758:
    // 0x8005D758: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D75C: addiu       $t8, $t7, 0x3
    ctx->r24 = ADD32(ctx->r15, 0X3);
    // 0x8005D760: and         $t9, $t8, $at
    ctx->r25 = ctx->r24 & ctx->r1;
    // 0x8005D764: addiu       $t6, $t9, 0x4
    ctx->r14 = ADD32(ctx->r25, 0X4);
    // 0x8005D768: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D76C: lw          $t8, -0x4($t6)
    ctx->r24 = MEM_W(ctx->r14, -0X4);
    // 0x8005D770: lw          $t7, 0x2C($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X2C);
    // 0x8005D774: b           L_8005D840
    // 0x8005D778: sw          $t7, 0x0($t8)
    MEM_W(0X0, ctx->r24) = ctx->r15;
        goto L_8005D840;
    // 0x8005D778: sw          $t7, 0x0($t8)
    MEM_W(0X0, ctx->r24) = ctx->r15;
L_8005D77C:
    // 0x8005D77C: lw          $t9, 0x0($a2)
    ctx->r25 = MEM_W(ctx->r6, 0X0);
    // 0x8005D780: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D784: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x8005D788: addiu       $t6, $t9, 0x3
    ctx->r14 = ADD32(ctx->r25, 0X3);
    // 0x8005D78C: and         $t7, $t6, $at
    ctx->r15 = ctx->r14 & ctx->r1;
    // 0x8005D790: addiu       $t8, $t7, 0x4
    ctx->r24 = ADD32(ctx->r15, 0X4);
    // 0x8005D794: sw          $t8, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r24;
    // 0x8005D798: lw          $t6, -0x4($t8)
    ctx->r14 = MEM_W(ctx->r24, -0X4);
    // 0x8005D79C: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D7A0: addiu       $a1, $zero, 0x78
    ctx->r5 = ADD32(0, 0X78);
    // 0x8005D7A4: sra         $t8, $t6, 31
    ctx->r24 = S32(SIGNED(ctx->r14) >> 31);
    // 0x8005D7A8: sw          $t6, 0x4($s0)
    MEM_W(0X4, ctx->r16) = ctx->r14;
    // 0x8005D7AC: addu        $t6, $t7, $a3
    ctx->r14 = ADD32(ctx->r15, ctx->r7);
    // 0x8005D7B0: sw          $t8, 0x0($s0)
    MEM_W(0X0, ctx->r16) = ctx->r24;
    // 0x8005D7B4: jal         0x80064CA0
    // 0x8005D7B8: sw          $t6, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r14;
    _Litob(rdram, ctx);
        goto after_3;
    // 0x8005D7B8: sw          $t6, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r14;
    after_3:
    // 0x8005D7BC: b           L_8005D844
    // 0x8005D7C0: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
        goto L_8005D844;
    // 0x8005D7C0: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_8005D7C4:
    // 0x8005D7C4: lw          $t8, 0x0($a2)
    ctx->r24 = MEM_W(ctx->r6, 0X0);
    // 0x8005D7C8: addiu       $at, $zero, -0x4
    ctx->r1 = ADD32(0, -0X4);
    // 0x8005D7CC: addiu       $t9, $t8, 0x3
    ctx->r25 = ADD32(ctx->r24, 0X3);
    // 0x8005D7D0: and         $t7, $t9, $at
    ctx->r15 = ctx->r25 & ctx->r1;
    // 0x8005D7D4: addiu       $t6, $t7, 0x4
    ctx->r14 = ADD32(ctx->r15, 0X4);
    // 0x8005D7D8: sw          $t6, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r14;
    // 0x8005D7DC: lw          $a0, -0x4($t6)
    ctx->r4 = MEM_W(ctx->r14, -0X4);
    // 0x8005D7E0: jal         0x8005E27C
    // 0x8005D7E4: sw          $a0, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r4;
    strlen_recomp(rdram, ctx);
        goto after_4;
    // 0x8005D7E4: sw          $a0, 0x8($s0)
    MEM_W(0X8, ctx->r16) = ctx->r4;
    after_4:
    // 0x8005D7E8: lw          $v1, 0x24($s0)
    ctx->r3 = MEM_W(ctx->r16, 0X24);
    // 0x8005D7EC: sw          $v0, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r2;
    // 0x8005D7F0: bltz        $v1, L_8005D840
    if (SIGNED(ctx->r3) < 0) {
        // 0x8005D7F4: slt         $at, $v1, $v0
        ctx->r1 = SIGNED(ctx->r3) < SIGNED(ctx->r2) ? 1 : 0;
            goto L_8005D840;
    }
    // 0x8005D7F4: slt         $at, $v1, $v0
    ctx->r1 = SIGNED(ctx->r3) < SIGNED(ctx->r2) ? 1 : 0;
    // 0x8005D7F8: beql        $at, $zero, L_8005D844
    if (ctx->r1 == 0) {
        // 0x8005D7FC: lw          $ra, 0x14($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X14);
            goto L_8005D844;
    }
    goto skip_18;
    // 0x8005D7FC: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    skip_18:
    // 0x8005D800: b           L_8005D840
    // 0x8005D804: sw          $v1, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r3;
        goto L_8005D840;
    // 0x8005D804: sw          $v1, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r3;
    // 0x8005D808: lw          $t8, 0xC($s0)
    ctx->r24 = MEM_W(ctx->r16, 0XC);
L_8005D80C:
    // 0x8005D80C: addiu       $t6, $zero, 0x25
    ctx->r14 = ADD32(0, 0X25);
    // 0x8005D810: addu        $t9, $a3, $t8
    ctx->r25 = ADD32(ctx->r7, ctx->r24);
    // 0x8005D814: sb          $t6, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r14;
    // 0x8005D818: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D81C: addiu       $t8, $t7, 0x1
    ctx->r24 = ADD32(ctx->r15, 0X1);
    // 0x8005D820: b           L_8005D840
    // 0x8005D824: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
        goto L_8005D840;
    // 0x8005D824: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
L_8005D828:
    // 0x8005D828: lw          $t6, 0xC($s0)
    ctx->r14 = MEM_W(ctx->r16, 0XC);
L_8005D82C:
    // 0x8005D82C: addu        $t9, $a3, $t6
    ctx->r25 = ADD32(ctx->r7, ctx->r14);
    // 0x8005D830: sb          $a1, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r5;
    // 0x8005D834: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x8005D838: addiu       $t8, $t7, 0x1
    ctx->r24 = ADD32(ctx->r15, 0X1);
    // 0x8005D83C: sw          $t8, 0xC($s0)
    MEM_W(0XC, ctx->r16) = ctx->r24;
L_8005D840:
    // 0x8005D840: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_8005D844:
    // 0x8005D844: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x8005D848: jr          $ra
    // 0x8005D84C: nop

    return;
    // 0x8005D84C: nop

;}
RECOMP_FUNC void static_5_8005FB90(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8005FB90: lw          $t6, 0x44($a0)
    ctx->r14 = MEM_W(ctx->r4, 0X44);
    // 0x8005FB94: mtc1        $a1, $f4
    ctx->f4.u32l = ctx->r5;
    // 0x8005FB98: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x8005FB9C: mtc1        $t6, $f8
    ctx->f8.u32l = ctx->r14;
    // 0x8005FBA0: cvt.s.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.fl = CVT_S_W(ctx->f4.u32l);
    // 0x8005FBA4: ldc1        $f4, -0x1B50($at)
    CHECK_FR(ctx, 4);
    ctx->f4.u64 = LD(ctx->r1, -0X1B50);
    // 0x8005FBA8: lui         $at, 0x3FE0
    ctx->r1 = S32(0X3FE0 << 16);
    // 0x8005FBAC: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x8005FBB0: cvt.s.w     $f10, $f8
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    ctx->f10.fl = CVT_S_W(ctx->f8.u32l);
    // 0x8005FBB4: mul.s       $f16, $f6, $f10
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f6.fl); NAN_CHECK(ctx->f10.fl); 
    ctx->f16.fl = MUL_S(ctx->f6.fl, ctx->f10.fl);
    // 0x8005FBB8: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x8005FBBC: cvt.d.s     $f18, $f16
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 16);
    NAN_CHECK(ctx->f16.fl); 
    ctx->f18.d = CVT_D_S(ctx->f16.fl);
    // 0x8005FBC0: div.d       $f8, $f18, $f4
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f4.d); 
    ctx->f8.d = DIV_D(ctx->f18.d, ctx->f4.d);
    // 0x8005FBC4: add.d       $f10, $f8, $f6
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f8.d); NAN_CHECK(ctx->f6.d); 
    ctx->f10.d = ctx->f8.d + ctx->f6.d;
    // 0x8005FBC8: cvt.s.d     $f0, $f10
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 10);
    NAN_CHECK(ctx->f10.d); 
    ctx->f0.fl = CVT_S_D(ctx->f10.d);
    // 0x8005FBCC: trunc.w.s   $f16, $f0
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 0);
    ctx->f16.u32l = TRUNC_W_S(ctx->f0.fl);
    // 0x8005FBD0: mfc1        $v0, $f16
    ctx->r2 = (int32_t)ctx->f16.u32l;
    // 0x8005FBD4: jr          $ra
    // 0x8005FBD8: nop

    return;
    // 0x8005FBD8: nop

;}
RECOMP_FUNC void static_5_8005FC04(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x8005FC04: sw          $zero, 0x0($a1)
    MEM_W(0X0, ctx->r5) = 0;
    // 0x8005FC08: lw          $v1, 0x0($a0)
    ctx->r3 = MEM_W(ctx->r4, 0X0);
    // 0x8005FC0C: lui         $v0, 0x7FFF
    ctx->r2 = S32(0X7FFF << 16);
    // 0x8005FC10: ori         $v0, $v0, 0xFFFF
    ctx->r2 = ctx->r2 | 0XFFFF;
    // 0x8005FC14: beql        $v1, $zero, L_8005FC54
    if (ctx->r3 == 0) {
        // 0x8005FC18: lw          $t9, 0x0($a1)
        ctx->r25 = MEM_W(ctx->r5, 0X0);
            goto L_8005FC54;
    }
    goto skip_0;
    // 0x8005FC18: lw          $t9, 0x0($a1)
    ctx->r25 = MEM_W(ctx->r5, 0X0);
    skip_0:
    // 0x8005FC1C: lw          $a2, 0x20($a0)
    ctx->r6 = MEM_W(ctx->r4, 0X20);
    // 0x8005FC20: lw          $t6, 0x10($v1)
    ctx->r14 = MEM_W(ctx->r3, 0X10);
L_8005FC24:
    // 0x8005FC24: subu        $t7, $t6, $a2
    ctx->r15 = SUB32(ctx->r14, ctx->r6);
    // 0x8005FC28: slt         $at, $t7, $v0
    ctx->r1 = SIGNED(ctx->r15) < SIGNED(ctx->r2) ? 1 : 0;
    // 0x8005FC2C: beql        $at, $zero, L_8005FC48
    if (ctx->r1 == 0) {
        // 0x8005FC30: lw          $v1, 0x0($v1)
        ctx->r3 = MEM_W(ctx->r3, 0X0);
            goto L_8005FC48;
    }
    goto skip_1;
    // 0x8005FC30: lw          $v1, 0x0($v1)
    ctx->r3 = MEM_W(ctx->r3, 0X0);
    skip_1:
    // 0x8005FC34: sw          $v1, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r3;
    // 0x8005FC38: lw          $t8, 0x10($v1)
    ctx->r24 = MEM_W(ctx->r3, 0X10);
    // 0x8005FC3C: lw          $a2, 0x20($a0)
    ctx->r6 = MEM_W(ctx->r4, 0X20);
    // 0x8005FC40: subu        $v0, $t8, $a2
    ctx->r2 = SUB32(ctx->r24, ctx->r6);
    // 0x8005FC44: lw          $v1, 0x0($v1)
    ctx->r3 = MEM_W(ctx->r3, 0X0);
L_8005FC48:
    // 0x8005FC48: bnel        $v1, $zero, L_8005FC24
    if (ctx->r3 != 0) {
        // 0x8005FC4C: lw          $t6, 0x10($v1)
        ctx->r14 = MEM_W(ctx->r3, 0X10);
            goto L_8005FC24;
    }
    goto skip_2;
    // 0x8005FC4C: lw          $t6, 0x10($v1)
    ctx->r14 = MEM_W(ctx->r3, 0X10);
    skip_2:
    // 0x8005FC50: lw          $t9, 0x0($a1)
    ctx->r25 = MEM_W(ctx->r5, 0X0);
L_8005FC54:
    // 0x8005FC54: jr          $ra
    // 0x8005FC58: lw          $v0, 0x10($t9)
    ctx->r2 = MEM_W(ctx->r25, 0X10);
    return;
    // 0x8005FC58: lw          $v0, 0x10($t9)
    ctx->r2 = MEM_W(ctx->r25, 0X10);
    // 0x8005FC5C: nop

;}
RECOMP_FUNC void static_5_80060C58(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80060C58: addiu       $sp, $sp, -0x60
    ctx->r29 = ADD32(ctx->r29, -0X60);
    // 0x80060C5C: sw          $ra, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r31;
    // 0x80060C60: sw          $s1, 0x20($sp)
    MEM_W(0X20, ctx->r29) = ctx->r17;
    // 0x80060C64: sw          $s0, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r16;
    // 0x80060C68: sw          $a1, 0x64($sp)
    MEM_W(0X64, ctx->r29) = ctx->r5;
    // 0x80060C6C: sw          $a2, 0x68($sp)
    MEM_W(0X68, ctx->r29) = ctx->r6;
    // 0x80060C70: sw          $a3, 0x6C($sp)
    MEM_W(0X6C, ctx->r29) = ctx->r7;
    // 0x80060C74: lw          $t6, 0x48($a0)
    ctx->r14 = MEM_W(ctx->r4, 0X48);
    // 0x80060C78: addiu       $at, $zero, 0x1
    ctx->r1 = ADD32(0, 0X1);
    // 0x80060C7C: or          $s0, $a0, $zero
    ctx->r16 = ctx->r4 | 0;
    // 0x80060C80: bne         $t6, $at, L_80060C90
    if (ctx->r14 != ctx->r1) {
        // 0x80060C84: lw          $s1, 0x0($a0)
        ctx->r17 = MEM_W(ctx->r4, 0X0);
            goto L_80060C90;
    }
    // 0x80060C84: lw          $s1, 0x0($a0)
    ctx->r17 = MEM_W(ctx->r4, 0X0);
    // 0x80060C88: bne         $a3, $zero, L_80060C98
    if (ctx->r7 != 0) {
        // 0x80060C8C: lw          $t8, 0x74($sp)
        ctx->r24 = MEM_W(ctx->r29, 0X74);
            goto L_80060C98;
    }
    // 0x80060C8C: lw          $t8, 0x74($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X74);
L_80060C90:
    // 0x80060C90: b           L_80060F2C
    // 0x80060C94: lw          $v0, 0x74($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X74);
        goto L_80060F2C;
    // 0x80060C94: lw          $v0, 0x74($sp)
    ctx->r2 = MEM_W(ctx->r29, 0X74);
L_80060C98:
    // 0x80060C98: sw          $t8, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r24;
    // 0x80060C9C: lw          $t9, 0x4($s1)
    ctx->r25 = MEM_W(ctx->r17, 0X4);
    // 0x80060CA0: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x80060CA4: lw          $a1, 0x64($sp)
    ctx->r5 = MEM_W(ctx->r29, 0X64);
    // 0x80060CA8: lw          $a2, 0x6C($sp)
    ctx->r6 = MEM_W(ctx->r29, 0X6C);
    // 0x80060CAC: jalr        $t9
    // 0x80060CB0: lw          $a3, 0x70($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X70);
    LOOKUP_FUNC(ctx->r25)(rdram, ctx);
        goto after_0;
    // 0x80060CB0: lw          $a3, 0x70($sp)
    ctx->r7 = MEM_W(ctx->r29, 0X70);
    after_0:
    // 0x80060CB4: lw          $t0, 0x64($sp)
    ctx->r8 = MEM_W(ctx->r29, 0X64);
    // 0x80060CB8: lui         $at, 0x800
    ctx->r1 = S32(0X800 << 16);
    // 0x80060CBC: lw          $a0, 0x68($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X68);
    // 0x80060CC0: lh          $t1, 0x0($t0)
    ctx->r9 = MEM_H(ctx->r8, 0X0);
    // 0x80060CC4: addiu       $s1, $v0, 0x10
    ctx->r17 = ADD32(ctx->r2, 0X10);
    // 0x80060CC8: andi        $t2, $t1, 0xFFFF
    ctx->r10 = ctx->r9 & 0XFFFF;
    // 0x80060CCC: or          $t3, $t2, $at
    ctx->r11 = ctx->r10 | ctx->r1;
    // 0x80060CD0: sw          $t3, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r11;
    // 0x80060CD4: lw          $t4, 0x6C($sp)
    ctx->r12 = MEM_W(ctx->r29, 0X6C);
    // 0x80060CD8: lui         $at, 0x808
    ctx->r1 = S32(0X808 << 16);
    // 0x80060CDC: sll         $t5, $t4, 1
    ctx->r13 = S32(ctx->r12 << 1);
    // 0x80060CE0: sw          $t5, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r13;
    // 0x80060CE4: lh          $t6, 0x0($a0)
    ctx->r14 = MEM_H(ctx->r4, 0X0);
    // 0x80060CE8: andi        $t0, $t5, 0xFFFF
    ctx->r8 = ctx->r13 & 0XFFFF;
    // 0x80060CEC: addiu       $t8, $t6, 0x440
    ctx->r24 = ADD32(ctx->r14, 0X440);
    // 0x80060CF0: sll         $t9, $t8, 16
    ctx->r25 = S32(ctx->r24 << 16);
    // 0x80060CF4: or          $t1, $t9, $t0
    ctx->r9 = ctx->r25 | ctx->r8;
    // 0x80060CF8: sw          $t1, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r9;
    // 0x80060CFC: lh          $t2, 0x0($a0)
    ctx->r10 = MEM_H(ctx->r4, 0X0);
    // 0x80060D00: addiu       $t3, $t2, 0x580
    ctx->r11 = ADD32(ctx->r10, 0X580);
    // 0x80060D04: andi        $t4, $t3, 0xFFFF
    ctx->r12 = ctx->r11 & 0XFFFF;
    // 0x80060D08: or          $t6, $t4, $at
    ctx->r14 = ctx->r12 | ctx->r1;
    // 0x80060D0C: sw          $t6, 0x8($v0)
    MEM_W(0X8, ctx->r2) = ctx->r14;
    // 0x80060D10: lh          $v1, 0x0($a0)
    ctx->r3 = MEM_H(ctx->r4, 0X0);
    // 0x80060D14: lui         $t6, 0x8008
    ctx->r14 = S32(0X8008 << 16);
    // 0x80060D18: addiu       $t7, $v1, 0x800
    ctx->r15 = ADD32(ctx->r3, 0X800);
    // 0x80060D1C: addiu       $t9, $v1, 0x6C0
    ctx->r25 = ADD32(ctx->r3, 0X6C0);
    // 0x80060D20: sll         $t0, $t9, 16
    ctx->r8 = S32(ctx->r25 << 16);
    // 0x80060D24: andi        $t8, $t7, 0xFFFF
    ctx->r24 = ctx->r15 & 0XFFFF;
    // 0x80060D28: or          $t1, $t8, $t0
    ctx->r9 = ctx->r24 | ctx->r8;
    // 0x80060D2C: sw          $t1, 0xC($v0)
    MEM_W(0XC, ctx->r2) = ctx->r9;
    // 0x80060D30: lw          $t2, 0x38($s0)
    ctx->r10 = MEM_W(ctx->r16, 0X38);
    // 0x80060D34: lui         $t7, 0x308
    ctx->r15 = S32(0X308 << 16);
    // 0x80060D38: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x80060D3C: beql        $t2, $zero, L_80060EEC
    if (ctx->r10 == 0) {
        // 0x80060D40: sw          $t7, 0x0($v1)
        MEM_W(0X0, ctx->r3) = ctx->r15;
            goto L_80060EEC;
    }
    goto skip_0;
    // 0x80060D40: sw          $t7, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r15;
    skip_0:
    // 0x80060D44: lh          $t3, 0x18($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X18);
    // 0x80060D48: sw          $zero, 0x38($s0)
    MEM_W(0X38, ctx->r16) = 0;
    // 0x80060D4C: lh          $t7, 0x1A($s0)
    ctx->r15 = MEM_H(ctx->r16, 0X1A);
    // 0x80060D50: sll         $t4, $t3, 1
    ctx->r12 = S32(ctx->r11 << 1);
    // 0x80060D54: addu        $t6, $t6, $t4
    ctx->r14 = ADD32(ctx->r14, ctx->r12);
    // 0x80060D58: lh          $t6, -0x54B0($t6)
    ctx->r14 = MEM_H(ctx->r14, -0X54B0);
    // 0x80060D5C: lh          $t8, 0x1C($s0)
    ctx->r24 = MEM_H(ctx->r16, 0X1C);
    // 0x80060D60: lw          $t1, 0x34($s0)
    ctx->r9 = MEM_W(ctx->r16, 0X34);
    // 0x80060D64: multu       $t6, $t7
    result = U64(U32(ctx->r14)) * U64(U32(ctx->r15)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x80060D68: mtc1        $t8, $f4
    ctx->f4.u32l = ctx->r24;
    // 0x80060D6C: addiu       $t2, $s0, 0x24
    ctx->r10 = ADD32(ctx->r16, 0X24);
    // 0x80060D70: cvt.d.w     $f12, $f4
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 4);
    ctx->f12.d = CVT_D_W(ctx->f4.u32l);
    // 0x80060D74: mflo        $t5
    ctx->r13 = lo;
    // 0x80060D78: sra         $t9, $t5, 15
    ctx->r25 = S32(SIGNED(ctx->r13) >> 15);
    // 0x80060D7C: sh          $t9, 0x28($s0)
    MEM_H(0X28, ctx->r16) = ctx->r25;
    // 0x80060D80: lh          $t0, 0x28($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X28);
    // 0x80060D84: sw          $t2, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r10;
    // 0x80060D88: sw          $t1, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r9;
    // 0x80060D8C: mtc1        $t0, $f6
    ctx->f6.u32l = ctx->r8;
    // 0x80060D90: jal         0x80061054
    // 0x80060D94: cvt.d.w     $f14, $f6
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 6);
    ctx->f14.d = CVT_D_W(ctx->f6.u32l);
    env_static_80061054(rdram, ctx);
        goto after_1;
    // 0x80060D94: cvt.d.w     $f14, $f6
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 6);
    ctx->f14.d = CVT_D_W(ctx->f6.u32l);
    after_1:
    // 0x80060D98: lh          $t3, 0x18($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X18);
    // 0x80060D9C: lui         $t7, 0x8008
    ctx->r15 = S32(0X8008 << 16);
    // 0x80060DA0: sh          $v0, 0x26($s0)
    MEM_H(0X26, ctx->r16) = ctx->r2;
    // 0x80060DA4: sll         $t4, $t3, 1
    ctx->r12 = S32(ctx->r11 << 1);
    // 0x80060DA8: negu        $t6, $t4
    ctx->r14 = SUB32(0, ctx->r12);
    // 0x80060DAC: addu        $t7, $t7, $t6
    ctx->r15 = ADD32(ctx->r15, ctx->r14);
    // 0x80060DB0: lh          $t7, -0x53B2($t7)
    ctx->r15 = MEM_H(ctx->r15, -0X53B2);
    // 0x80060DB4: lh          $t5, 0x1A($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X1A);
    // 0x80060DB8: lh          $t0, 0x1E($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X1E);
    // 0x80060DBC: lw          $t2, 0x34($s0)
    ctx->r10 = MEM_W(ctx->r16, 0X34);
    // 0x80060DC0: multu       $t7, $t5
    result = U64(U32(ctx->r15)) * U64(U32(ctx->r13)); lo = S32(result >> 0); hi = S32(result >> 32);
    // 0x80060DC4: mtc1        $t0, $f8
    ctx->f8.u32l = ctx->r8;
    // 0x80060DC8: addiu       $t3, $s0, 0x2A
    ctx->r11 = ADD32(ctx->r16, 0X2A);
    // 0x80060DCC: cvt.d.w     $f12, $f8
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 8);
    ctx->f12.d = CVT_D_W(ctx->f8.u32l);
    // 0x80060DD0: mflo        $t9
    ctx->r25 = lo;
    // 0x80060DD4: sra         $t8, $t9, 15
    ctx->r24 = S32(SIGNED(ctx->r25) >> 15);
    // 0x80060DD8: sh          $t8, 0x2E($s0)
    MEM_H(0X2E, ctx->r16) = ctx->r24;
    // 0x80060DDC: lh          $t1, 0x2E($s0)
    ctx->r9 = MEM_H(ctx->r16, 0X2E);
    // 0x80060DE0: sw          $t3, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r11;
    // 0x80060DE4: sw          $t2, 0x10($sp)
    MEM_W(0X10, ctx->r29) = ctx->r10;
    // 0x80060DE8: mtc1        $t1, $f10
    ctx->f10.u32l = ctx->r9;
    // 0x80060DEC: jal         0x80061054
    // 0x80060DF0: cvt.d.w     $f14, $f10
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 10);
    ctx->f14.d = CVT_D_W(ctx->f10.u32l);
    env_static_80061054(rdram, ctx);
        goto after_2;
    // 0x80060DF0: cvt.d.w     $f14, $f10
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 10);
    ctx->f14.d = CVT_D_W(ctx->f10.u32l);
    after_2:
    // 0x80060DF4: lh          $t4, 0x1C($s0)
    ctx->r12 = MEM_H(ctx->r16, 0X1C);
    // 0x80060DF8: sh          $v0, 0x2C($s0)
    MEM_H(0X2C, ctx->r16) = ctx->r2;
    // 0x80060DFC: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x80060E00: lui         $at, 0x906
    ctx->r1 = S32(0X906 << 16);
    // 0x80060E04: andi        $t6, $t4, 0xFFFF
    ctx->r14 = ctx->r12 & 0XFFFF;
    // 0x80060E08: or          $t7, $t6, $at
    ctx->r15 = ctx->r14 | ctx->r1;
    // 0x80060E0C: sw          $t7, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r15;
    // 0x80060E10: sw          $zero, 0x4($v1)
    MEM_W(0X4, ctx->r3) = 0;
    // 0x80060E14: lh          $t5, 0x1E($s0)
    ctx->r13 = MEM_H(ctx->r16, 0X1E);
    // 0x80060E18: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80060E1C: or          $a0, $s1, $zero
    ctx->r4 = ctx->r17 | 0;
    // 0x80060E20: lui         $at, 0x904
    ctx->r1 = S32(0X904 << 16);
    // 0x80060E24: andi        $t9, $t5, 0xFFFF
    ctx->r25 = ctx->r13 & 0XFFFF;
    // 0x80060E28: or          $t8, $t9, $at
    ctx->r24 = ctx->r25 | ctx->r1;
    // 0x80060E2C: sw          $t8, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r24;
    // 0x80060E30: sw          $zero, 0x4($a0)
    MEM_W(0X4, ctx->r4) = 0;
    // 0x80060E34: lh          $t0, 0x28($s0)
    ctx->r8 = MEM_H(ctx->r16, 0X28);
    // 0x80060E38: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80060E3C: lui         $at, 0x902
    ctx->r1 = S32(0X902 << 16);
    // 0x80060E40: andi        $t1, $t0, 0xFFFF
    ctx->r9 = ctx->r8 & 0XFFFF;
    // 0x80060E44: or          $t2, $t1, $at
    ctx->r10 = ctx->r9 | ctx->r1;
    // 0x80060E48: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x80060E4C: sw          $t2, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r10;
    // 0x80060E50: lh          $t4, 0x26($s0)
    ctx->r12 = MEM_H(ctx->r16, 0X26);
    // 0x80060E54: lhu         $t5, 0x24($s0)
    ctx->r13 = MEM_HU(ctx->r16, 0X24);
    // 0x80060E58: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80060E5C: sll         $t6, $t4, 16
    ctx->r14 = S32(ctx->r12 << 16);
    // 0x80060E60: or          $t9, $t6, $t5
    ctx->r25 = ctx->r14 | ctx->r13;
    // 0x80060E64: sw          $t9, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r25;
    // 0x80060E68: lh          $t8, 0x2E($s0)
    ctx->r24 = MEM_H(ctx->r16, 0X2E);
    // 0x80060E6C: lui         $at, 0x900
    ctx->r1 = S32(0X900 << 16);
    // 0x80060E70: or          $a2, $s1, $zero
    ctx->r6 = ctx->r17 | 0;
    // 0x80060E74: andi        $t0, $t8, 0xFFFF
    ctx->r8 = ctx->r24 & 0XFFFF;
    // 0x80060E78: or          $t1, $t0, $at
    ctx->r9 = ctx->r8 | ctx->r1;
    // 0x80060E7C: sw          $t1, 0x0($a2)
    MEM_W(0X0, ctx->r6) = ctx->r9;
    // 0x80060E80: lh          $t3, 0x2C($s0)
    ctx->r11 = MEM_H(ctx->r16, 0X2C);
    // 0x80060E84: lhu         $t6, 0x2A($s0)
    ctx->r14 = MEM_HU(ctx->r16, 0X2A);
    // 0x80060E88: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80060E8C: sll         $t4, $t3, 16
    ctx->r12 = S32(ctx->r11 << 16);
    // 0x80060E90: or          $t5, $t4, $t6
    ctx->r13 = ctx->r12 | ctx->r14;
    // 0x80060E94: sw          $t5, 0x4($a2)
    MEM_W(0X4, ctx->r6) = ctx->r13;
    // 0x80060E98: lh          $t9, 0x20($s0)
    ctx->r25 = MEM_H(ctx->r16, 0X20);
    // 0x80060E9C: lui         $at, 0x908
    ctx->r1 = S32(0X908 << 16);
    // 0x80060EA0: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x80060EA4: andi        $t8, $t9, 0xFFFF
    ctx->r24 = ctx->r25 & 0XFFFF;
    // 0x80060EA8: or          $t0, $t8, $at
    ctx->r8 = ctx->r24 | ctx->r1;
    // 0x80060EAC: sw          $t0, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r8;
    // 0x80060EB0: lh          $t1, 0x22($s0)
    ctx->r9 = MEM_H(ctx->r16, 0X22);
    // 0x80060EB4: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    // 0x80060EB8: or          $v1, $s1, $zero
    ctx->r3 = ctx->r17 | 0;
    // 0x80060EBC: andi        $t2, $t1, 0xFFFF
    ctx->r10 = ctx->r9 & 0XFFFF;
    // 0x80060EC0: sw          $t2, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r10;
    // 0x80060EC4: lui         $t3, 0x309
    ctx->r11 = S32(0X309 << 16);
    // 0x80060EC8: sw          $t3, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r11;
    // 0x80060ECC: lw          $a0, 0x14($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X14);
    // 0x80060ED0: sw          $v1, 0x34($sp)
    MEM_W(0X34, ctx->r29) = ctx->r3;
    // 0x80060ED4: jal         0x80059090
    // 0x80060ED8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    osVirtualToPhysical_recomp(rdram, ctx);
        goto after_3;
    // 0x80060ED8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    after_3:
    // 0x80060EDC: lw          $v1, 0x34($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X34);
    // 0x80060EE0: b           L_80060F04
    // 0x80060EE4: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
        goto L_80060F04;
    // 0x80060EE4: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
    // 0x80060EE8: sw          $t7, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r15;
L_80060EEC:
    // 0x80060EEC: lw          $a0, 0x14($s0)
    ctx->r4 = MEM_W(ctx->r16, 0X14);
    // 0x80060EF0: sw          $v1, 0x30($sp)
    MEM_W(0X30, ctx->r29) = ctx->r3;
    // 0x80060EF4: jal         0x80059090
    // 0x80060EF8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    osVirtualToPhysical_recomp(rdram, ctx);
        goto after_4;
    // 0x80060EF8: addiu       $s1, $s1, 0x8
    ctx->r17 = ADD32(ctx->r17, 0X8);
    after_4:
    // 0x80060EFC: lw          $v1, 0x30($sp)
    ctx->r3 = MEM_W(ctx->r29, 0X30);
    // 0x80060F00: sw          $v0, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r2;
L_80060F04:
    // 0x80060F04: lw          $t4, 0x64($sp)
    ctx->r12 = MEM_W(ctx->r29, 0X64);
    // 0x80060F08: lw          $t5, 0x2C($sp)
    ctx->r13 = MEM_W(ctx->r29, 0X2C);
    // 0x80060F0C: or          $v0, $s1, $zero
    ctx->r2 = ctx->r17 | 0;
    // 0x80060F10: lh          $t6, 0x0($t4)
    ctx->r14 = MEM_H(ctx->r12, 0X0);
    // 0x80060F14: addu        $t9, $t6, $t5
    ctx->r25 = ADD32(ctx->r14, ctx->r13);
    // 0x80060F18: sh          $t9, 0x0($t4)
    MEM_H(0X0, ctx->r12) = ctx->r25;
    // 0x80060F1C: lw          $t8, 0x30($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X30);
    // 0x80060F20: lw          $t0, 0x6C($sp)
    ctx->r8 = MEM_W(ctx->r29, 0X6C);
    // 0x80060F24: addu        $t1, $t8, $t0
    ctx->r9 = ADD32(ctx->r24, ctx->r8);
    // 0x80060F28: sw          $t1, 0x30($s0)
    MEM_W(0X30, ctx->r16) = ctx->r9;
L_80060F2C:
    // 0x80060F2C: lw          $ra, 0x24($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X24);
    // 0x80060F30: lw          $s0, 0x1C($sp)
    ctx->r16 = MEM_W(ctx->r29, 0X1C);
    // 0x80060F34: lw          $s1, 0x20($sp)
    ctx->r17 = MEM_W(ctx->r29, 0X20);
    // 0x80060F38: jr          $ra
    // 0x80060F3C: addiu       $sp, $sp, 0x60
    ctx->r29 = ADD32(ctx->r29, 0X60);
    return;
    // 0x80060F3C: addiu       $sp, $sp, 0x60
    ctx->r29 = ADD32(ctx->r29, 0X60);
;}
RECOMP_FUNC void static_5_80061B70(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80061B70: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x80061B74: sw          $s3, 0x2C($sp)
    MEM_W(0X2C, ctx->r29) = ctx->r19;
    // 0x80061B78: sw          $s5, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r21;
    // 0x80061B7C: sll         $t6, $s3, 16
    ctx->r14 = S32(ctx->r19 << 16);
    // 0x80061B80: sll         $t8, $s5, 16
    ctx->r24 = S32(ctx->r21 << 16);
    // 0x80061B84: sra         $s5, $t8, 16
    ctx->r21 = S32(SIGNED(ctx->r24) >> 16);
    // 0x80061B88: sra         $s3, $t6, 16
    ctx->r19 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80061B8C: blez        $s1, L_80061BF8
    if (SIGNED(ctx->r17) <= 0) {
        // 0x80061B90: sw          $ra, 0x14($sp)
        MEM_W(0X14, ctx->r29) = ctx->r31;
            goto L_80061BF8;
    }
    // 0x80061B90: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x80061B94: lw          $t9, 0x30($s2)
    ctx->r25 = MEM_W(ctx->r18, 0X30);
    // 0x80061B98: lw          $a0, 0x44($s2)
    ctx->r4 = MEM_W(ctx->r18, 0X44);
    // 0x80061B9C: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x80061BA0: jalr        $t9
    // 0x80061BA4: lw          $a2, 0x34($s2)
    ctx->r6 = MEM_W(ctx->r18, 0X34);
    LOOKUP_FUNC(ctx->r25)(rdram, ctx);
        goto after_0;
    // 0x80061BA4: lw          $a2, 0x34($s2)
    ctx->r6 = MEM_W(ctx->r18, 0X34);
    after_0:
    // 0x80061BA8: andi        $a2, $v0, 0x7
    ctx->r6 = ctx->r2 & 0X7;
    // 0x80061BAC: addu        $s1, $s1, $a2
    ctx->r17 = ADD32(ctx->r17, ctx->r6);
    // 0x80061BB0: andi        $t6, $s3, 0xFFFF
    ctx->r14 = ctx->r19 & 0XFFFF;
    // 0x80061BB4: lui         $at, 0x800
    ctx->r1 = S32(0X800 << 16);
    // 0x80061BB8: or          $t7, $t6, $at
    ctx->r15 = ctx->r14 | ctx->r1;
    // 0x80061BBC: andi        $t8, $s1, 0x7
    ctx->r24 = ctx->r17 & 0X7;
    // 0x80061BC0: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x80061BC4: subu        $t9, $s1, $t8
    ctx->r25 = SUB32(ctx->r17, ctx->r24);
    // 0x80061BC8: addiu       $t6, $t9, 0x8
    ctx->r14 = ADD32(ctx->r25, 0X8);
    // 0x80061BCC: sw          $t7, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r15;
    // 0x80061BD0: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
    // 0x80061BD4: andi        $t7, $t6, 0xFFFF
    ctx->r15 = ctx->r14 & 0XFFFF;
    // 0x80061BD8: or          $a1, $s0, $zero
    ctx->r5 = ctx->r16 | 0;
    // 0x80061BDC: sw          $t7, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r15;
    // 0x80061BE0: subu        $t9, $v0, $a2
    ctx->r25 = SUB32(ctx->r2, ctx->r6);
    // 0x80061BE4: lui         $t8, 0x400
    ctx->r24 = S32(0X400 << 16);
    // 0x80061BE8: sw          $t8, 0x0($a1)
    MEM_W(0X0, ctx->r5) = ctx->r24;
    // 0x80061BEC: sw          $t9, 0x4($a1)
    MEM_W(0X4, ctx->r5) = ctx->r25;
    // 0x80061BF0: b           L_80061BFC
    // 0x80061BF4: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
        goto L_80061BFC;
    // 0x80061BF4: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
L_80061BF8:
    // 0x80061BF8: or          $a2, $zero, $zero
    ctx->r6 = 0 | 0;
L_80061BFC:
    // 0x80061BFC: andi        $t6, $s4, 0x2
    ctx->r14 = ctx->r20 & 0X2;
    // 0x80061C00: beq         $t6, $zero, L_80061C28
    if (ctx->r14 == 0) {
        // 0x80061C04: or          $v0, $s0, $zero
        ctx->r2 = ctx->r16 | 0;
            goto L_80061C28;
    }
    // 0x80061C04: or          $v0, $s0, $zero
    ctx->r2 = ctx->r16 | 0;
    // 0x80061C08: lui         $t7, 0xF00
    ctx->r15 = S32(0XF00 << 16);
    // 0x80061C0C: sw          $t7, 0x0($v0)
    MEM_W(0X0, ctx->r2) = ctx->r15;
    // 0x80061C10: lw          $t8, 0x18($s2)
    ctx->r24 = MEM_W(ctx->r18, 0X18);
    // 0x80061C14: lui         $at, 0x1FFF
    ctx->r1 = S32(0X1FFF << 16);
    // 0x80061C18: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x80061C1C: and         $t9, $t8, $at
    ctx->r25 = ctx->r24 & ctx->r1;
    // 0x80061C20: sw          $t9, 0x4($v0)
    MEM_W(0X4, ctx->r2) = ctx->r25;
    // 0x80061C24: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
L_80061C28:
    // 0x80061C28: addu        $t6, $s3, $a2
    ctx->r14 = ADD32(ctx->r19, ctx->r6);
    // 0x80061C2C: andi        $t7, $t6, 0xFFFF
    ctx->r15 = ctx->r14 & 0XFFFF;
    // 0x80061C30: lui         $at, 0x800
    ctx->r1 = S32(0X800 << 16);
    // 0x80061C34: or          $t8, $t7, $at
    ctx->r24 = ctx->r15 | ctx->r1;
    // 0x80061C38: or          $v1, $s0, $zero
    ctx->r3 = ctx->r16 | 0;
    // 0x80061C3C: sw          $t8, 0x0($v1)
    MEM_W(0X0, ctx->r3) = ctx->r24;
    // 0x80061C40: sll         $t7, $s6, 1
    ctx->r15 = S32(ctx->r22 << 1);
    // 0x80061C44: andi        $t8, $t7, 0xFFFF
    ctx->r24 = ctx->r15 & 0XFFFF;
    // 0x80061C48: sll         $t6, $s5, 16
    ctx->r14 = S32(ctx->r21 << 16);
    // 0x80061C4C: or          $t9, $t6, $t8
    ctx->r25 = ctx->r14 | ctx->r24;
    // 0x80061C50: andi        $t7, $s4, 0xFF
    ctx->r15 = ctx->r20 & 0XFF;
    // 0x80061C54: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
    // 0x80061C58: sll         $t6, $t7, 16
    ctx->r14 = S32(ctx->r15 << 16);
    // 0x80061C5C: lui         $at, 0x100
    ctx->r1 = S32(0X100 << 16);
    // 0x80061C60: sw          $t9, 0x4($v1)
    MEM_W(0X4, ctx->r3) = ctx->r25;
    // 0x80061C64: or          $t8, $t6, $at
    ctx->r24 = ctx->r14 | ctx->r1;
    // 0x80061C68: or          $a0, $s0, $zero
    ctx->r4 = ctx->r16 | 0;
    // 0x80061C6C: sw          $t8, 0x0($a0)
    MEM_W(0X0, ctx->r4) = ctx->r24;
    // 0x80061C70: lw          $t9, 0x14($s2)
    ctx->r25 = MEM_W(ctx->r18, 0X14);
    // 0x80061C74: lui         $at, 0x1FFF
    ctx->r1 = S32(0X1FFF << 16);
    // 0x80061C78: ori         $at, $at, 0xFFFF
    ctx->r1 = ctx->r1 | 0XFFFF;
    // 0x80061C7C: and         $t7, $t9, $at
    ctx->r15 = ctx->r25 & ctx->r1;
    // 0x80061C80: sw          $t7, 0x4($a0)
    MEM_W(0X4, ctx->r4) = ctx->r15;
    // 0x80061C84: sw          $zero, 0x40($s2)
    MEM_W(0X40, ctx->r18) = 0;
    // 0x80061C88: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    // 0x80061C8C: addiu       $s0, $s0, 0x8
    ctx->r16 = ADD32(ctx->r16, 0X8);
    // 0x80061C90: or          $v0, $s0, $zero
    ctx->r2 = ctx->r16 | 0;
    // 0x80061C94: jr          $ra
    // 0x80061C98: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    return;
    // 0x80061C98: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
;}
RECOMP_FUNC void static_5_80064050(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x80064050: addiu       $sp, $sp, -0x18
    ctx->r29 = ADD32(ctx->r29, -0X18);
    // 0x80064054: sw          $s2, 0x28($sp)
    MEM_W(0X28, ctx->r29) = ctx->r18;
    // 0x80064058: sll         $t6, $s2, 16
    ctx->r14 = S32(ctx->r18 << 16);
    // 0x8006405C: sra         $s2, $t6, 16
    ctx->r18 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80064060: sw          $s3, 0x24($sp)
    MEM_W(0X24, ctx->r29) = ctx->r19;
    // 0x80064064: sll         $t8, $s3, 16
    ctx->r24 = S32(ctx->r19 << 16);
    // 0x80064068: sra         $s3, $t8, 16
    ctx->r19 = S32(SIGNED(ctx->r24) >> 16);
    // 0x8006406C: andi        $t6, $s4, 0xFF
    ctx->r14 = ctx->r20 & 0XFF;
    // 0x80064070: sw          $s4, 0x1C($sp)
    MEM_W(0X1C, ctx->r29) = ctx->r20;
    // 0x80064074: or          $s4, $t6, $zero
    ctx->r20 = ctx->r14 | 0;
    // 0x80064078: bgtz        $s3, L_8006408C
    if (SIGNED(ctx->r19) > 0) {
        // 0x8006407C: sw          $ra, 0x14($sp)
        MEM_W(0X14, ctx->r29) = ctx->r31;
            goto L_8006408C;
    }
    // 0x8006407C: sw          $ra, 0x14($sp)
    MEM_W(0X14, ctx->r29) = ctx->r31;
    // 0x80064080: lui         $s1, 0x8008
    ctx->r17 = S32(0X8008 << 16);
    // 0x80064084: addiu       $s1, $s1, -0x19D0
    ctx->r17 = ADD32(ctx->r17, -0X19D0);
    // 0x80064088: addiu       $s3, $zero, 0x1
    ctx->r19 = ADD32(0, 0X1);
L_8006408C:
    // 0x8006408C: addiu       $v0, $zero, 0x66
    ctx->r2 = ADD32(0, 0X66);
    // 0x80064090: beq         $v0, $s4, L_800640C4
    if (ctx->r2 == ctx->r20) {
        // 0x80064094: or          $v1, $s4, $zero
        ctx->r3 = ctx->r20 | 0;
            goto L_800640C4;
    }
    // 0x80064094: or          $v1, $s4, $zero
    ctx->r3 = ctx->r20 | 0;
    // 0x80064098: addiu       $a0, $zero, 0x67
    ctx->r4 = ADD32(0, 0X67);
    // 0x8006409C: beq         $a0, $v1, L_800640A8
    if (ctx->r4 == ctx->r3) {
        // 0x800640A0: addiu       $at, $zero, 0x47
        ctx->r1 = ADD32(0, 0X47);
            goto L_800640A8;
    }
    // 0x800640A0: addiu       $at, $zero, 0x47
    ctx->r1 = ADD32(0, 0X47);
    // 0x800640A4: bne         $v1, $at, L_80064300
    if (ctx->r3 != ctx->r1) {
        // 0x800640A8: slti        $at, $s2, -0x4
        ctx->r1 = SIGNED(ctx->r18) < -0X4 ? 1 : 0;
            goto L_80064300;
    }
L_800640A8:
    // 0x800640A8: slti        $at, $s2, -0x4
    ctx->r1 = SIGNED(ctx->r18) < -0X4 ? 1 : 0;
    // 0x800640AC: bne         $at, $zero, L_80064300
    if (ctx->r1 != 0) {
        // 0x800640B0: nop
    
            goto L_80064300;
    }
    // 0x800640B0: nop

    // 0x800640B4: lw          $t7, 0x24($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X24);
    // 0x800640B8: slt         $at, $s2, $t7
    ctx->r1 = SIGNED(ctx->r18) < SIGNED(ctx->r15) ? 1 : 0;
    // 0x800640BC: beq         $at, $zero, L_80064300
    if (ctx->r1 == 0) {
        // 0x800640C0: nop
    
            goto L_80064300;
    }
    // 0x800640C0: nop

L_800640C4:
    // 0x800640C4: addiu       $s2, $s2, 0x1
    ctx->r18 = ADD32(ctx->r18, 0X1);
    // 0x800640C8: sll         $t8, $s2, 16
    ctx->r24 = S32(ctx->r18 << 16);
    // 0x800640CC: beq         $v0, $v1, L_80064108
    if (ctx->r2 == ctx->r3) {
        // 0x800640D0: sra         $s2, $t8, 16
        ctx->r18 = S32(SIGNED(ctx->r24) >> 16);
            goto L_80064108;
    }
    // 0x800640D0: sra         $s2, $t8, 16
    ctx->r18 = S32(SIGNED(ctx->r24) >> 16);
    // 0x800640D4: lw          $t6, 0x30($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X30);
    // 0x800640D8: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x800640DC: andi        $t7, $t6, 0x8
    ctx->r15 = ctx->r14 & 0X8;
    // 0x800640E0: bne         $t7, $zero, L_800640F8
    if (ctx->r15 != 0) {
        // 0x800640E4: slt         $at, $s3, $v0
        ctx->r1 = SIGNED(ctx->r19) < SIGNED(ctx->r2) ? 1 : 0;
            goto L_800640F8;
    }
    // 0x800640E4: slt         $at, $s3, $v0
    ctx->r1 = SIGNED(ctx->r19) < SIGNED(ctx->r2) ? 1 : 0;
    // 0x800640E8: beql        $at, $zero, L_800640FC
    if (ctx->r1 == 0) {
        // 0x800640EC: subu        $t8, $v0, $s2
        ctx->r24 = SUB32(ctx->r2, ctx->r18);
            goto L_800640FC;
    }
    goto skip_0;
    // 0x800640EC: subu        $t8, $v0, $s2
    ctx->r24 = SUB32(ctx->r2, ctx->r18);
    skip_0:
    // 0x800640F0: sw          $s3, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r19;
    // 0x800640F4: or          $v0, $s3, $zero
    ctx->r2 = ctx->r19 | 0;
L_800640F8:
    // 0x800640F8: subu        $t8, $v0, $s2
    ctx->r24 = SUB32(ctx->r2, ctx->r18);
L_800640FC:
    // 0x800640FC: bgez        $t8, L_80064108
    if (SIGNED(ctx->r24) >= 0) {
        // 0x80064100: sw          $t8, 0x24($s0)
        MEM_W(0X24, ctx->r16) = ctx->r24;
            goto L_80064108;
    }
    // 0x80064100: sw          $t8, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r24;
    // 0x80064104: sw          $zero, 0x24($s0)
    MEM_W(0X24, ctx->r16) = 0;
L_80064108:
    // 0x80064108: bgtz        $s2, L_800641D8
    if (SIGNED(ctx->r18) > 0) {
        // 0x8006410C: slt         $at, $s3, $s2
        ctx->r1 = SIGNED(ctx->r19) < SIGNED(ctx->r18) ? 1 : 0;
            goto L_800641D8;
    }
    // 0x8006410C: slt         $at, $s3, $s2
    ctx->r1 = SIGNED(ctx->r19) < SIGNED(ctx->r18) ? 1 : 0;
    // 0x80064110: lw          $t7, 0x8($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X8);
    // 0x80064114: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x80064118: addiu       $t6, $zero, 0x30
    ctx->r14 = ADD32(0, 0X30);
    // 0x8006411C: negu        $v1, $s2
    ctx->r3 = SUB32(0, ctx->r18);
    // 0x80064120: addu        $t9, $t7, $t8
    ctx->r25 = ADD32(ctx->r15, ctx->r24);
    // 0x80064124: sb          $t6, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r14;
    // 0x80064128: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x8006412C: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x80064130: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x80064134: addiu       $t8, $t7, 0x1
    ctx->r24 = ADD32(ctx->r15, 0X1);
    // 0x80064138: bgtz        $v0, L_80064150
    if (SIGNED(ctx->r2) > 0) {
        // 0x8006413C: sw          $t8, 0x14($s0)
        MEM_W(0X14, ctx->r16) = ctx->r24;
            goto L_80064150;
    }
    // 0x8006413C: sw          $t8, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r24;
    // 0x80064140: lw          $t6, 0x30($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X30);
    // 0x80064144: andi        $t9, $t6, 0x8
    ctx->r25 = ctx->r14 & 0X8;
    // 0x80064148: beql        $t9, $zero, L_80064178
    if (ctx->r25 == 0) {
        // 0x8006414C: slt         $at, $v0, $v1
        ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
            goto L_80064178;
    }
    goto skip_1;
    // 0x8006414C: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    skip_1:
L_80064150:
    // 0x80064150: lw          $t8, 0x8($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X8);
    // 0x80064154: lw          $t6, 0x14($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X14);
    // 0x80064158: addiu       $t7, $zero, 0x2E
    ctx->r15 = ADD32(0, 0X2E);
    // 0x8006415C: addu        $t9, $t8, $t6
    ctx->r25 = ADD32(ctx->r24, ctx->r14);
    // 0x80064160: sb          $t7, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r15;
    // 0x80064164: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x80064168: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x8006416C: addiu       $t6, $t8, 0x1
    ctx->r14 = ADD32(ctx->r24, 0X1);
    // 0x80064170: sw          $t6, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r14;
    // 0x80064174: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
L_80064178:
    // 0x80064178: beql        $at, $zero, L_80064194
    if (ctx->r1 == 0) {
        // 0x8006417C: addu        $t8, $v0, $s2
        ctx->r24 = ADD32(ctx->r2, ctx->r18);
            goto L_80064194;
    }
    goto skip_2;
    // 0x8006417C: addu        $t8, $v0, $s2
    ctx->r24 = ADD32(ctx->r2, ctx->r18);
    skip_2:
    // 0x80064180: negu        $s2, $v0
    ctx->r18 = SUB32(0, ctx->r2);
    // 0x80064184: sll         $t7, $s2, 16
    ctx->r15 = S32(ctx->r18 << 16);
    // 0x80064188: sra         $s2, $t7, 16
    ctx->r18 = S32(SIGNED(ctx->r15) >> 16);
    // 0x8006418C: negu        $v1, $s2
    ctx->r3 = SUB32(0, ctx->r18);
    // 0x80064190: addu        $t8, $v0, $s2
    ctx->r24 = ADD32(ctx->r2, ctx->r18);
L_80064194:
    // 0x80064194: slt         $at, $t8, $s3
    ctx->r1 = SIGNED(ctx->r24) < SIGNED(ctx->r19) ? 1 : 0;
    // 0x80064198: sw          $v1, 0x18($s0)
    MEM_W(0X18, ctx->r16) = ctx->r3;
    // 0x8006419C: beq         $at, $zero, L_800641B0
    if (ctx->r1 == 0) {
        // 0x800641A0: sw          $t8, 0x24($s0)
        MEM_W(0X24, ctx->r16) = ctx->r24;
            goto L_800641B0;
    }
    // 0x800641A0: sw          $t8, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r24;
    // 0x800641A4: sll         $s3, $t8, 16
    ctx->r19 = S32(ctx->r24 << 16);
    // 0x800641A8: sra         $t6, $s3, 16
    ctx->r14 = S32(SIGNED(ctx->r19) >> 16);
    // 0x800641AC: or          $s3, $t6, $zero
    ctx->r19 = ctx->r14 | 0;
L_800641B0:
    // 0x800641B0: lw          $t7, 0x8($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X8);
    // 0x800641B4: lw          $t9, 0x14($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X14);
    // 0x800641B8: sw          $s3, 0x1C($s0)
    MEM_W(0X1C, ctx->r16) = ctx->r19;
    // 0x800641BC: or          $a2, $s3, $zero
    ctx->r6 = ctx->r19 | 0;
    // 0x800641C0: jal         0x8005E250
    // 0x800641C4: addu        $a0, $t7, $t9
    ctx->r4 = ADD32(ctx->r15, ctx->r25);
    memcpy_recomp(rdram, ctx);
        goto after_0;
    // 0x800641C4: addu        $a0, $t7, $t9
    ctx->r4 = ADD32(ctx->r15, ctx->r25);
    after_0:
    // 0x800641C8: lw          $t8, 0x24($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X24);
    // 0x800641CC: subu        $t6, $t8, $s3
    ctx->r14 = SUB32(ctx->r24, ctx->r19);
    // 0x800641D0: b           L_8006455C
    // 0x800641D4: sw          $t6, 0x20($s0)
    MEM_W(0X20, ctx->r16) = ctx->r14;
        goto L_8006455C;
    // 0x800641D4: sw          $t6, 0x20($s0)
    MEM_W(0X20, ctx->r16) = ctx->r14;
L_800641D8:
    // 0x800641D8: beq         $at, $zero, L_80064250
    if (ctx->r1 == 0) {
        // 0x800641DC: or          $a1, $s1, $zero
        ctx->r5 = ctx->r17 | 0;
            goto L_80064250;
    }
    // 0x800641DC: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x800641E0: lw          $t7, 0x8($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X8);
    // 0x800641E4: lw          $t9, 0x14($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X14);
    // 0x800641E8: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x800641EC: or          $a2, $s3, $zero
    ctx->r6 = ctx->r19 | 0;
    // 0x800641F0: jal         0x8005E250
    // 0x800641F4: addu        $a0, $t7, $t9
    ctx->r4 = ADD32(ctx->r15, ctx->r25);
    memcpy_recomp(rdram, ctx);
        goto after_1;
    // 0x800641F4: addu        $a0, $t7, $t9
    ctx->r4 = ADD32(ctx->r15, ctx->r25);
    after_1:
    // 0x800641F8: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x800641FC: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x80064200: subu        $t7, $s2, $s3
    ctx->r15 = SUB32(ctx->r18, ctx->r19);
    // 0x80064204: addu        $t6, $t8, $s3
    ctx->r14 = ADD32(ctx->r24, ctx->r19);
    // 0x80064208: sw          $t6, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r14;
    // 0x8006420C: bgtz        $v0, L_80064224
    if (SIGNED(ctx->r2) > 0) {
        // 0x80064210: sw          $t7, 0x18($s0)
        MEM_W(0X18, ctx->r16) = ctx->r15;
            goto L_80064224;
    }
    // 0x80064210: sw          $t7, 0x18($s0)
    MEM_W(0X18, ctx->r16) = ctx->r15;
    // 0x80064214: lw          $t9, 0x30($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X30);
    // 0x80064218: andi        $t8, $t9, 0x8
    ctx->r24 = ctx->r25 & 0X8;
    // 0x8006421C: beq         $t8, $zero, L_80064248
    if (ctx->r24 == 0) {
        // 0x80064220: nop
    
            goto L_80064248;
    }
    // 0x80064220: nop

L_80064224:
    // 0x80064224: lw          $t7, 0x8($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X8);
    // 0x80064228: lw          $t9, 0x14($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X14);
    // 0x8006422C: addiu       $t6, $zero, 0x2E
    ctx->r14 = ADD32(0, 0X2E);
    // 0x80064230: addu        $t8, $t7, $t9
    ctx->r24 = ADD32(ctx->r15, ctx->r25);
    // 0x80064234: sb          $t6, 0x0($t8)
    MEM_B(0X0, ctx->r24) = ctx->r14;
    // 0x80064238: lw          $t7, 0x1C($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X1C);
    // 0x8006423C: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x80064240: addiu       $t9, $t7, 0x1
    ctx->r25 = ADD32(ctx->r15, 0X1);
    // 0x80064244: sw          $t9, 0x1C($s0)
    MEM_W(0X1C, ctx->r16) = ctx->r25;
L_80064248:
    // 0x80064248: b           L_8006455C
    // 0x8006424C: sw          $v0, 0x20($s0)
    MEM_W(0X20, ctx->r16) = ctx->r2;
        goto L_8006455C;
    // 0x8006424C: sw          $v0, 0x20($s0)
    MEM_W(0X20, ctx->r16) = ctx->r2;
L_80064250:
    // 0x80064250: lw          $t6, 0x8($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X8);
    // 0x80064254: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x80064258: or          $a2, $s2, $zero
    ctx->r6 = ctx->r18 | 0;
    // 0x8006425C: jal         0x8005E250
    // 0x80064260: addu        $a0, $t6, $t8
    ctx->r4 = ADD32(ctx->r14, ctx->r24);
    memcpy_recomp(rdram, ctx);
        goto after_2;
    // 0x80064260: addu        $a0, $t6, $t8
    ctx->r4 = ADD32(ctx->r14, ctx->r24);
    after_2:
    // 0x80064264: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x80064268: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x8006426C: subu        $s3, $s3, $s2
    ctx->r19 = SUB32(ctx->r19, ctx->r18);
    // 0x80064270: sll         $t6, $s3, 16
    ctx->r14 = S32(ctx->r19 << 16);
    // 0x80064274: addu        $t9, $t7, $s2
    ctx->r25 = ADD32(ctx->r15, ctx->r18);
    // 0x80064278: sw          $t9, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r25;
    // 0x8006427C: bgtz        $v0, L_80064294
    if (SIGNED(ctx->r2) > 0) {
        // 0x80064280: sra         $s3, $t6, 16
        ctx->r19 = S32(SIGNED(ctx->r14) >> 16);
            goto L_80064294;
    }
    // 0x80064280: sra         $s3, $t6, 16
    ctx->r19 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80064284: lw          $t7, 0x30($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X30);
    // 0x80064288: andi        $t9, $t7, 0x8
    ctx->r25 = ctx->r15 & 0X8;
    // 0x8006428C: beql        $t9, $zero, L_800642BC
    if (ctx->r25 == 0) {
        // 0x80064290: slt         $at, $v0, $s3
        ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r19) ? 1 : 0;
            goto L_800642BC;
    }
    goto skip_3;
    // 0x80064290: slt         $at, $v0, $s3
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r19) ? 1 : 0;
    skip_3:
L_80064294:
    // 0x80064294: lw          $t8, 0x8($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X8);
    // 0x80064298: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x8006429C: addiu       $t6, $zero, 0x2E
    ctx->r14 = ADD32(0, 0X2E);
    // 0x800642A0: addu        $t9, $t8, $t7
    ctx->r25 = ADD32(ctx->r24, ctx->r15);
    // 0x800642A4: sb          $t6, 0x0($t9)
    MEM_B(0X0, ctx->r25) = ctx->r14;
    // 0x800642A8: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x800642AC: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x800642B0: addiu       $t7, $t8, 0x1
    ctx->r15 = ADD32(ctx->r24, 0X1);
    // 0x800642B4: sw          $t7, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r15;
    // 0x800642B8: slt         $at, $v0, $s3
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r19) ? 1 : 0;
L_800642BC:
    // 0x800642BC: beq         $at, $zero, L_800642D0
    if (ctx->r1 == 0) {
        // 0x800642C0: addu        $a1, $s2, $s1
        ctx->r5 = ADD32(ctx->r18, ctx->r17);
            goto L_800642D0;
    }
    // 0x800642C0: addu        $a1, $s2, $s1
    ctx->r5 = ADD32(ctx->r18, ctx->r17);
    // 0x800642C4: sll         $s3, $v0, 16
    ctx->r19 = S32(ctx->r2 << 16);
    // 0x800642C8: sra         $t6, $s3, 16
    ctx->r14 = S32(SIGNED(ctx->r19) >> 16);
    // 0x800642CC: or          $s3, $t6, $zero
    ctx->r19 = ctx->r14 | 0;
L_800642D0:
    // 0x800642D0: lw          $t9, 0x8($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X8);
    // 0x800642D4: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x800642D8: or          $a2, $s3, $zero
    ctx->r6 = ctx->r19 | 0;
    // 0x800642DC: jal         0x8005E250
    // 0x800642E0: addu        $a0, $t9, $t8
    ctx->r4 = ADD32(ctx->r25, ctx->r24);
    memcpy_recomp(rdram, ctx);
        goto after_3;
    // 0x800642E0: addu        $a0, $t9, $t8
    ctx->r4 = ADD32(ctx->r25, ctx->r24);
    after_3:
    // 0x800642E4: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x800642E8: lw          $t9, 0x24($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X24);
    // 0x800642EC: addu        $t6, $t7, $s3
    ctx->r14 = ADD32(ctx->r15, ctx->r19);
    // 0x800642F0: subu        $t8, $t9, $s3
    ctx->r24 = SUB32(ctx->r25, ctx->r19);
    // 0x800642F4: sw          $t6, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r14;
    // 0x800642F8: b           L_8006455C
    // 0x800642FC: sw          $t8, 0x18($s0)
    MEM_W(0X18, ctx->r16) = ctx->r24;
        goto L_8006455C;
    // 0x800642FC: sw          $t8, 0x18($s0)
    MEM_W(0X18, ctx->r16) = ctx->r24;
L_80064300:
    // 0x80064300: beq         $a0, $v1, L_80064310
    if (ctx->r4 == ctx->r3) {
        // 0x80064304: addiu       $at, $zero, 0x47
        ctx->r1 = ADD32(0, 0X47);
            goto L_80064310;
    }
    // 0x80064304: addiu       $at, $zero, 0x47
    ctx->r1 = ADD32(0, 0X47);
    // 0x80064308: bnel        $v1, $at, L_80064350
    if (ctx->r3 != ctx->r1) {
        // 0x8006430C: lw          $t8, 0x8($s0)
        ctx->r24 = MEM_W(ctx->r16, 0X8);
            goto L_80064350;
    }
    goto skip_4;
    // 0x8006430C: lw          $t8, 0x8($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X8);
    skip_4:
L_80064310:
    // 0x80064310: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x80064314: addiu       $s4, $zero, 0x45
    ctx->r20 = ADD32(0, 0X45);
    // 0x80064318: slt         $at, $s3, $v0
    ctx->r1 = SIGNED(ctx->r19) < SIGNED(ctx->r2) ? 1 : 0;
    // 0x8006431C: beql        $at, $zero, L_80064330
    if (ctx->r1 == 0) {
        // 0x80064320: addiu       $t7, $v0, -0x1
        ctx->r15 = ADD32(ctx->r2, -0X1);
            goto L_80064330;
    }
    goto skip_5;
    // 0x80064320: addiu       $t7, $v0, -0x1
    ctx->r15 = ADD32(ctx->r2, -0X1);
    skip_5:
    // 0x80064324: sw          $s3, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r19;
    // 0x80064328: or          $v0, $s3, $zero
    ctx->r2 = ctx->r19 | 0;
    // 0x8006432C: addiu       $t7, $v0, -0x1
    ctx->r15 = ADD32(ctx->r2, -0X1);
L_80064330:
    // 0x80064330: bgez        $t7, L_8006433C
    if (SIGNED(ctx->r15) >= 0) {
        // 0x80064334: sw          $t7, 0x24($s0)
        MEM_W(0X24, ctx->r16) = ctx->r15;
            goto L_8006433C;
    }
    // 0x80064334: sw          $t7, 0x24($s0)
    MEM_W(0X24, ctx->r16) = ctx->r15;
    // 0x80064338: sw          $zero, 0x24($s0)
    MEM_W(0X24, ctx->r16) = 0;
L_8006433C:
    // 0x8006433C: bne         $a0, $v1, L_8006434C
    if (ctx->r4 != ctx->r3) {
        // 0x80064340: nop
    
            goto L_8006434C;
    }
    // 0x80064340: nop

    // 0x80064344: b           L_8006434C
    // 0x80064348: addiu       $s4, $zero, 0x65
    ctx->r20 = ADD32(0, 0X65);
        goto L_8006434C;
    // 0x80064348: addiu       $s4, $zero, 0x65
    ctx->r20 = ADD32(0, 0X65);
L_8006434C:
    // 0x8006434C: lw          $t8, 0x8($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X8);
L_80064350:
    // 0x80064350: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x80064354: lbu         $t9, 0x0($s1)
    ctx->r25 = MEM_BU(ctx->r17, 0X0);
    // 0x80064358: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x8006435C: addu        $t6, $t8, $t7
    ctx->r14 = ADD32(ctx->r24, ctx->r15);
    // 0x80064360: sb          $t9, 0x0($t6)
    MEM_B(0X0, ctx->r14) = ctx->r25;
    // 0x80064364: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x80064368: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x8006436C: addiu       $t7, $t8, 0x1
    ctx->r15 = ADD32(ctx->r24, 0X1);
    // 0x80064370: bgtz        $v0, L_80064388
    if (SIGNED(ctx->r2) > 0) {
        // 0x80064374: sw          $t7, 0x14($s0)
        MEM_W(0X14, ctx->r16) = ctx->r15;
            goto L_80064388;
    }
    // 0x80064374: sw          $t7, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r15;
    // 0x80064378: lw          $t9, 0x30($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X30);
    // 0x8006437C: andi        $t6, $t9, 0x8
    ctx->r14 = ctx->r25 & 0X8;
    // 0x80064380: beq         $t6, $zero, L_800643AC
    if (ctx->r14 == 0) {
        // 0x80064384: nop
    
            goto L_800643AC;
    }
    // 0x80064384: nop

L_80064388:
    // 0x80064388: lw          $t7, 0x8($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X8);
    // 0x8006438C: lw          $t9, 0x14($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X14);
    // 0x80064390: addiu       $t8, $zero, 0x2E
    ctx->r24 = ADD32(0, 0X2E);
    // 0x80064394: addu        $t6, $t7, $t9
    ctx->r14 = ADD32(ctx->r15, ctx->r25);
    // 0x80064398: sb          $t8, 0x0($t6)
    MEM_B(0X0, ctx->r14) = ctx->r24;
    // 0x8006439C: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x800643A0: lw          $v0, 0x24($s0)
    ctx->r2 = MEM_W(ctx->r16, 0X24);
    // 0x800643A4: addiu       $t9, $t7, 0x1
    ctx->r25 = ADD32(ctx->r15, 0X1);
    // 0x800643A8: sw          $t9, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r25;
L_800643AC:
    // 0x800643AC: blezl       $v0, L_80064408
    if (SIGNED(ctx->r2) <= 0) {
        // 0x800643B0: lw          $t6, 0x8($s0)
        ctx->r14 = MEM_W(ctx->r16, 0X8);
            goto L_80064408;
    }
    goto skip_6;
    // 0x800643B0: lw          $t6, 0x8($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X8);
    skip_6:
    // 0x800643B4: addiu       $s3, $s3, -0x1
    ctx->r19 = ADD32(ctx->r19, -0X1);
    // 0x800643B8: sll         $t8, $s3, 16
    ctx->r24 = S32(ctx->r19 << 16);
    // 0x800643BC: sra         $s3, $t8, 16
    ctx->r19 = S32(SIGNED(ctx->r24) >> 16);
    // 0x800643C0: slt         $at, $v0, $s3
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r19) ? 1 : 0;
    // 0x800643C4: beq         $at, $zero, L_800643D8
    if (ctx->r1 == 0) {
        // 0x800643C8: or          $a1, $s1, $zero
        ctx->r5 = ctx->r17 | 0;
            goto L_800643D8;
    }
    // 0x800643C8: or          $a1, $s1, $zero
    ctx->r5 = ctx->r17 | 0;
    // 0x800643CC: sll         $s3, $v0, 16
    ctx->r19 = S32(ctx->r2 << 16);
    // 0x800643D0: sra         $t7, $s3, 16
    ctx->r15 = S32(SIGNED(ctx->r19) >> 16);
    // 0x800643D4: or          $s3, $t7, $zero
    ctx->r19 = ctx->r15 | 0;
L_800643D8:
    // 0x800643D8: lw          $t9, 0x8($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X8);
    // 0x800643DC: lw          $t8, 0x14($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X14);
    // 0x800643E0: or          $a2, $s3, $zero
    ctx->r6 = ctx->r19 | 0;
    // 0x800643E4: jal         0x8005E250
    // 0x800643E8: addu        $a0, $t9, $t8
    ctx->r4 = ADD32(ctx->r25, ctx->r24);
    memcpy_recomp(rdram, ctx);
        goto after_4;
    // 0x800643E8: addu        $a0, $t9, $t8
    ctx->r4 = ADD32(ctx->r25, ctx->r24);
    after_4:
    // 0x800643EC: lw          $t6, 0x14($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X14);
    // 0x800643F0: lw          $t9, 0x24($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X24);
    // 0x800643F4: addu        $t7, $t6, $s3
    ctx->r15 = ADD32(ctx->r14, ctx->r19);
    // 0x800643F8: subu        $t8, $t9, $s3
    ctx->r24 = SUB32(ctx->r25, ctx->r19);
    // 0x800643FC: sw          $t7, 0x14($s0)
    MEM_W(0X14, ctx->r16) = ctx->r15;
    // 0x80064400: sw          $t8, 0x18($s0)
    MEM_W(0X18, ctx->r16) = ctx->r24;
    // 0x80064404: lw          $t6, 0x8($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X8);
L_80064408:
    // 0x80064408: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x8006440C: addu        $s1, $t6, $t7
    ctx->r17 = ADD32(ctx->r14, ctx->r15);
    // 0x80064410: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x80064414: bltz        $s2, L_8006442C
    if (SIGNED(ctx->r18) < 0) {
        // 0x80064418: sb          $s4, -0x1($s1)
        MEM_B(-0X1, ctx->r17) = ctx->r20;
            goto L_8006442C;
    }
    // 0x80064418: sb          $s4, -0x1($s1)
    MEM_B(-0X1, ctx->r17) = ctx->r20;
    // 0x8006441C: addiu       $t9, $zero, 0x2B
    ctx->r25 = ADD32(0, 0X2B);
    // 0x80064420: sb          $t9, 0x0($s1)
    MEM_B(0X0, ctx->r17) = ctx->r25;
    // 0x80064424: b           L_80064448
    // 0x80064428: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
        goto L_80064448;
    // 0x80064428: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
L_8006442C:
    // 0x8006442C: negu        $s2, $s2
    ctx->r18 = SUB32(0, ctx->r18);
    // 0x80064430: sll         $t6, $s2, 16
    ctx->r14 = S32(ctx->r18 << 16);
    // 0x80064434: addiu       $t8, $zero, 0x2D
    ctx->r24 = ADD32(0, 0X2D);
    // 0x80064438: sra         $t7, $t6, 16
    ctx->r15 = S32(SIGNED(ctx->r14) >> 16);
    // 0x8006443C: sb          $t8, 0x0($s1)
    MEM_B(0X0, ctx->r17) = ctx->r24;
    // 0x80064440: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x80064444: or          $s2, $t7, $zero
    ctx->r18 = ctx->r15 | 0;
L_80064448:
    // 0x80064448: slti        $at, $s2, 0x64
    ctx->r1 = SIGNED(ctx->r18) < 0X64 ? 1 : 0;
    // 0x8006444C: bnel        $at, $zero, L_800644F8
    if (ctx->r1 != 0) {
        // 0x80064450: addiu       $v0, $zero, 0xA
        ctx->r2 = ADD32(0, 0XA);
            goto L_800644F8;
    }
    goto skip_7;
    // 0x80064450: addiu       $v0, $zero, 0xA
    ctx->r2 = ADD32(0, 0XA);
    skip_7:
    // 0x80064454: slti        $at, $s2, 0x3E8
    ctx->r1 = SIGNED(ctx->r18) < 0X3E8 ? 1 : 0;
    // 0x80064458: bne         $at, $zero, L_800644A8
    if (ctx->r1 != 0) {
        // 0x8006445C: addiu       $v0, $zero, 0x3E8
        ctx->r2 = ADD32(0, 0X3E8);
            goto L_800644A8;
    }
    // 0x8006445C: addiu       $v0, $zero, 0x3E8
    ctx->r2 = ADD32(0, 0X3E8);
    // 0x80064460: div         $zero, $s2, $v0
    lo = S32(S64(S32(ctx->r18)) / S64(S32(ctx->r2))); hi = S32(S64(S32(ctx->r18)) % S64(S32(ctx->r2)));
    // 0x80064464: bne         $v0, $zero, L_80064470
    if (ctx->r2 != 0) {
        // 0x80064468: nop
    
            goto L_80064470;
    }
    // 0x80064468: nop

    // 0x8006446C: break       7
    do_break(2147894380);
L_80064470:
    // 0x80064470: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x80064474: bne         $v0, $at, L_80064488
    if (ctx->r2 != ctx->r1) {
        // 0x80064478: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_80064488;
    }
    // 0x80064478: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x8006447C: bne         $s2, $at, L_80064488
    if (ctx->r18 != ctx->r1) {
        // 0x80064480: nop
    
            goto L_80064488;
    }
    // 0x80064480: nop

    // 0x80064484: break       6
    do_break(2147894404);
L_80064488:
    // 0x80064488: mfhi        $s2
    ctx->r18 = hi;
    // 0x8006448C: sll         $t6, $s2, 16
    ctx->r14 = S32(ctx->r18 << 16);
    // 0x80064490: mflo        $t9
    ctx->r25 = lo;
    // 0x80064494: addiu       $t8, $t9, 0x30
    ctx->r24 = ADD32(ctx->r25, 0X30);
    // 0x80064498: sra         $t7, $t6, 16
    ctx->r15 = S32(SIGNED(ctx->r14) >> 16);
    // 0x8006449C: or          $s2, $t7, $zero
    ctx->r18 = ctx->r15 | 0;
    // 0x800644A0: sb          $t8, 0x0($s1)
    MEM_B(0X0, ctx->r17) = ctx->r24;
    // 0x800644A4: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
L_800644A8:
    // 0x800644A8: addiu       $v0, $zero, 0x64
    ctx->r2 = ADD32(0, 0X64);
    // 0x800644AC: div         $zero, $s2, $v0
    lo = S32(S64(S32(ctx->r18)) / S64(S32(ctx->r2))); hi = S32(S64(S32(ctx->r18)) % S64(S32(ctx->r2)));
    // 0x800644B0: bne         $v0, $zero, L_800644BC
    if (ctx->r2 != 0) {
        // 0x800644B4: nop
    
            goto L_800644BC;
    }
    // 0x800644B4: nop

    // 0x800644B8: break       7
    do_break(2147894456);
L_800644BC:
    // 0x800644BC: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x800644C0: bne         $v0, $at, L_800644D4
    if (ctx->r2 != ctx->r1) {
        // 0x800644C4: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_800644D4;
    }
    // 0x800644C4: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x800644C8: bne         $s2, $at, L_800644D4
    if (ctx->r18 != ctx->r1) {
        // 0x800644CC: nop
    
            goto L_800644D4;
    }
    // 0x800644CC: nop

    // 0x800644D0: break       6
    do_break(2147894480);
L_800644D4:
    // 0x800644D4: mfhi        $s2
    ctx->r18 = hi;
    // 0x800644D8: sll         $t6, $s2, 16
    ctx->r14 = S32(ctx->r18 << 16);
    // 0x800644DC: mflo        $t9
    ctx->r25 = lo;
    // 0x800644E0: addiu       $t8, $t9, 0x30
    ctx->r24 = ADD32(ctx->r25, 0X30);
    // 0x800644E4: sra         $t7, $t6, 16
    ctx->r15 = S32(SIGNED(ctx->r14) >> 16);
    // 0x800644E8: or          $s2, $t7, $zero
    ctx->r18 = ctx->r15 | 0;
    // 0x800644EC: sb          $t8, 0x0($s1)
    MEM_B(0X0, ctx->r17) = ctx->r24;
    // 0x800644F0: addiu       $s1, $s1, 0x1
    ctx->r17 = ADD32(ctx->r17, 0X1);
    // 0x800644F4: addiu       $v0, $zero, 0xA
    ctx->r2 = ADD32(0, 0XA);
L_800644F8:
    // 0x800644F8: div         $zero, $s2, $v0
    lo = S32(S64(S32(ctx->r18)) / S64(S32(ctx->r2))); hi = S32(S64(S32(ctx->r18)) % S64(S32(ctx->r2)));
    // 0x800644FC: bne         $v0, $zero, L_80064508
    if (ctx->r2 != 0) {
        // 0x80064500: nop
    
            goto L_80064508;
    }
    // 0x80064500: nop

    // 0x80064504: break       7
    do_break(2147894532);
L_80064508:
    // 0x80064508: addiu       $at, $zero, -0x1
    ctx->r1 = ADD32(0, -0X1);
    // 0x8006450C: bne         $v0, $at, L_80064520
    if (ctx->r2 != ctx->r1) {
        // 0x80064510: lui         $at, 0x8000
        ctx->r1 = S32(0X8000 << 16);
            goto L_80064520;
    }
    // 0x80064510: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x80064514: bne         $s2, $at, L_80064520
    if (ctx->r18 != ctx->r1) {
        // 0x80064518: nop
    
            goto L_80064520;
    }
    // 0x80064518: nop

    // 0x8006451C: break       6
    do_break(2147894556);
L_80064520:
    // 0x80064520: mfhi        $s2
    ctx->r18 = hi;
    // 0x80064524: sll         $t6, $s2, 16
    ctx->r14 = S32(ctx->r18 << 16);
    // 0x80064528: mflo        $t9
    ctx->r25 = lo;
    // 0x8006452C: addiu       $t8, $t9, 0x30
    ctx->r24 = ADD32(ctx->r25, 0X30);
    // 0x80064530: sra         $t7, $t6, 16
    ctx->r15 = S32(SIGNED(ctx->r14) >> 16);
    // 0x80064534: addiu       $t9, $t7, 0x30
    ctx->r25 = ADD32(ctx->r15, 0X30);
    // 0x80064538: sb          $t8, 0x0($s1)
    MEM_B(0X0, ctx->r17) = ctx->r24;
    // 0x8006453C: sb          $t9, 0x1($s1)
    MEM_B(0X1, ctx->r17) = ctx->r25;
    // 0x80064540: lw          $t8, 0x8($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X8);
    // 0x80064544: or          $s2, $t7, $zero
    ctx->r18 = ctx->r15 | 0;
    // 0x80064548: lw          $t7, 0x14($s0)
    ctx->r15 = MEM_W(ctx->r16, 0X14);
    // 0x8006454C: addiu       $s1, $s1, 0x2
    ctx->r17 = ADD32(ctx->r17, 0X2);
    // 0x80064550: subu        $t6, $s1, $t8
    ctx->r14 = SUB32(ctx->r17, ctx->r24);
    // 0x80064554: subu        $t9, $t6, $t7
    ctx->r25 = SUB32(ctx->r14, ctx->r15);
    // 0x80064558: sw          $t9, 0x1C($s0)
    MEM_W(0X1C, ctx->r16) = ctx->r25;
L_8006455C:
    // 0x8006455C: lw          $t8, 0x30($s0)
    ctx->r24 = MEM_W(ctx->r16, 0X30);
    // 0x80064560: addiu       $at, $zero, 0x10
    ctx->r1 = ADD32(0, 0X10);
    // 0x80064564: andi        $t6, $t8, 0x14
    ctx->r14 = ctx->r24 & 0X14;
    // 0x80064568: bnel        $t6, $at, L_800645AC
    if (ctx->r14 != ctx->r1) {
        // 0x8006456C: lw          $ra, 0x14($sp)
        ctx->r31 = MEM_W(ctx->r29, 0X14);
            goto L_800645AC;
    }
    goto skip_8;
    // 0x8006456C: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
    skip_8:
    // 0x80064570: lw          $t7, 0xC($s0)
    ctx->r15 = MEM_W(ctx->r16, 0XC);
    // 0x80064574: lw          $t9, 0x14($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X14);
    // 0x80064578: lw          $t6, 0x18($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X18);
    // 0x8006457C: lw          $v1, 0x28($s0)
    ctx->r3 = MEM_W(ctx->r16, 0X28);
    // 0x80064580: addu        $t8, $t7, $t9
    ctx->r24 = ADD32(ctx->r15, ctx->r25);
    // 0x80064584: lw          $t9, 0x1C($s0)
    ctx->r25 = MEM_W(ctx->r16, 0X1C);
    // 0x80064588: addu        $t7, $t8, $t6
    ctx->r15 = ADD32(ctx->r24, ctx->r14);
    // 0x8006458C: lw          $t6, 0x20($s0)
    ctx->r14 = MEM_W(ctx->r16, 0X20);
    // 0x80064590: addu        $t8, $t7, $t9
    ctx->r24 = ADD32(ctx->r15, ctx->r25);
    // 0x80064594: addu        $v0, $t8, $t6
    ctx->r2 = ADD32(ctx->r24, ctx->r14);
    // 0x80064598: slt         $at, $v0, $v1
    ctx->r1 = SIGNED(ctx->r2) < SIGNED(ctx->r3) ? 1 : 0;
    // 0x8006459C: beq         $at, $zero, L_800645A8
    if (ctx->r1 == 0) {
        // 0x800645A0: subu        $t7, $v1, $v0
        ctx->r15 = SUB32(ctx->r3, ctx->r2);
            goto L_800645A8;
    }
    // 0x800645A0: subu        $t7, $v1, $v0
    ctx->r15 = SUB32(ctx->r3, ctx->r2);
    // 0x800645A4: sw          $t7, 0x10($s0)
    MEM_W(0X10, ctx->r16) = ctx->r15;
L_800645A8:
    // 0x800645A8: lw          $ra, 0x14($sp)
    ctx->r31 = MEM_W(ctx->r29, 0X14);
L_800645AC:
    // 0x800645AC: addiu       $sp, $sp, 0x18
    ctx->r29 = ADD32(ctx->r29, 0X18);
    // 0x800645B0: jr          $ra
    // 0x800645B4: nop

    return;
    // 0x800645B4: nop

    // 0x800645B8: jr          $ra
    // 0x800645BC: nop

    return;
    // 0x800645BC: nop

;}
RECOMP_FUNC void static_5_800477D0(uint8_t* rdram, recomp_context* ctx) {
    uint64_t hi = 0, lo = 0, result = 0;
    int c1cs = 0;
    // 0x800477D0: lw          $a0, 0x10($sp)
    ctx->r4 = MEM_W(ctx->r29, 0X10);
    // 0x800477D4: lui         $at, 0x3FF0
    ctx->r1 = S32(0X3FF0 << 16);
    // 0x800477D8: lw          $t3, 0x14($sp)
    ctx->r11 = MEM_W(ctx->r29, 0X14);
    // 0x800477DC: bnel        $a0, $zero, L_80047814
    if (ctx->r4 != 0) {
        // 0x800477E0: mtc1        $at, $f19
        ctx->f_odd[(19 - 1) * 2] = ctx->r1;
            goto L_80047814;
    }
    goto skip_0;
    // 0x800477E0: mtc1        $at, $f19
    ctx->f_odd[(19 - 1) * 2] = ctx->r1;
    skip_0:
    // 0x800477E4: c.le.d      $f12, $f14
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 14);
    c1cs = ctx->f12.d <= ctx->f14.d;
    // 0x800477E8: ori         $t6, $zero, 0xFFFF
    ctx->r14 = 0 | 0XFFFF;
    // 0x800477EC: lw          $t7, 0x14($sp)
    ctx->r15 = MEM_W(ctx->r29, 0X14);
    // 0x800477F0: lw          $t8, 0x14($sp)
    ctx->r24 = MEM_W(ctx->r29, 0X14);
    // 0x800477F4: bc1f        L_80047808
    if (!c1cs) {
        // 0x800477F8: addiu       $v0, $zero, -0x8000
        ctx->r2 = ADD32(0, -0X8000);
            goto L_80047808;
    }
    // 0x800477F8: addiu       $v0, $zero, -0x8000
    ctx->r2 = ADD32(0, -0X8000);
    // 0x800477FC: sh          $t6, 0x0($t7)
    MEM_H(0X0, ctx->r15) = ctx->r14;
    // 0x80047800: jr          $ra
    // 0x80047804: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
    return;
    // 0x80047804: addiu       $v0, $zero, 0x7FFF
    ctx->r2 = ADD32(0, 0X7FFF);
L_80047808:
    // 0x80047808: jr          $ra
    // 0x8004780C: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
    return;
    // 0x8004780C: sh          $zero, 0x0($t8)
    MEM_H(0X0, ctx->r24) = 0;
    // 0x80047810: mtc1        $at, $f19
    ctx->f_odd[(19 - 1) * 2] = ctx->r1;
L_80047814:
    // 0x80047814: mtc1        $zero, $f18
    ctx->f18.u32l = 0;
    // 0x80047818: mtc1        $a0, $f4
    ctx->f4.u32l = ctx->r4;
    // 0x8004781C: mtc1        $zero, $f9
    ctx->f_odd[(9 - 1) * 2] = 0;
    // 0x80047820: c.lt.d      $f14, $f18
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 18);
    c1cs = ctx->f14.d < ctx->f18.d;
    // 0x80047824: mtc1        $zero, $f8
    ctx->f8.u32l = 0;
    // 0x80047828: cvt.d.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.d = CVT_D_W(ctx->f4.u32l);
    // 0x8004782C: bc1f        L_80047838
    if (!c1cs) {
        // 0x80047830: div.d       $f0, $f18, $f6
        CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f6.d); 
    ctx->f0.d = DIV_D(ctx->f18.d, ctx->f6.d);
            goto L_80047838;
    }
    // 0x80047830: div.d       $f0, $f18, $f6
    CHECK_FR(ctx, 0);
    CHECK_FR(ctx, 18);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f18.d); NAN_CHECK(ctx->f6.d); 
    ctx->f0.d = DIV_D(ctx->f18.d, ctx->f6.d);
    // 0x80047834: mov.d       $f14, $f18
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 18);
    ctx->f14.d = ctx->f18.d;
L_80047838:
    // 0x80047838: c.le.d      $f12, $f8
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 8);
    c1cs = ctx->f12.d <= ctx->f8.d;
    // 0x8004783C: nop

    // 0x80047840: bc1fl       L_80047850
    if (!c1cs) {
        // 0x80047844: sub.d       $f10, $f14, $f12
        CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
            goto L_80047850;
    }
    goto skip_1;
    // 0x80047844: sub.d       $f10, $f14, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
    skip_1:
    // 0x80047848: mov.d       $f12, $f18
    CHECK_FR(ctx, 12);
    CHECK_FR(ctx, 18);
    ctx->f12.d = ctx->f18.d;
    // 0x8004784C: sub.d       $f10, $f14, $f12
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 14);
    CHECK_FR(ctx, 12);
    NAN_CHECK(ctx->f14.d); NAN_CHECK(ctx->f12.d); 
    ctx->f10.d = ctx->f14.d - ctx->f12.d;
L_80047850:
    // 0x80047850: lui         $at, 0x4020
    ctx->r1 = S32(0X4020 << 16);
    // 0x80047854: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x80047858: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x8004785C: mul.d       $f4, $f10, $f0
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 0);
    NAN_CHECK(ctx->f10.d); NAN_CHECK(ctx->f0.d); 
    ctx->f4.d = MUL_D(ctx->f10.d, ctx->f0.d);
    // 0x80047860: lui         $at, 0x8008
    ctx->r1 = S32(0X8008 << 16);
    // 0x80047864: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x80047868: mul.d       $f2, $f4, $f6
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.d); NAN_CHECK(ctx->f6.d); 
    ctx->f2.d = MUL_D(ctx->f4.d, ctx->f6.d);
    // 0x8004786C: trunc.w.d   $f8, $f2
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 2);
    ctx->f8.u32l = TRUNC_W_D(ctx->f2.d);
    // 0x80047870: mfc1        $v1, $f8
    ctx->r3 = (int32_t)ctx->f8.u32l;
    // 0x80047874: nop

    // 0x80047878: sll         $v1, $v1, 16
    ctx->r3 = S32(ctx->r3 << 16);
    // 0x8004787C: sra         $v1, $v1, 16
    ctx->r3 = S32(SIGNED(ctx->r3) >> 16);
    // 0x80047880: mtc1        $v1, $f10
    ctx->f10.u32l = ctx->r3;
    // 0x80047884: addiu       $t6, $v1, -0x1
    ctx->r14 = ADD32(ctx->r3, -0X1);
    // 0x80047888: cvt.d.w     $f4, $f10
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    ctx->f4.d = CVT_D_W(ctx->f10.u32l);
    // 0x8004788C: ldc1        $f10, -0x3338($at)
    CHECK_FR(ctx, 10);
    ctx->f10.u64 = LD(ctx->r1, -0X3338);
    // 0x80047890: lui         $at, 0x41E0
    ctx->r1 = S32(0X41E0 << 16);
    // 0x80047894: sub.d       $f6, $f2, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 2);
    CHECK_FR(ctx, 4);
    NAN_CHECK(ctx->f2.d); NAN_CHECK(ctx->f4.d); 
    ctx->f6.d = ctx->f2.d - ctx->f4.d;
    // 0x80047898: add.d       $f16, $f6, $f18
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 18);
    NAN_CHECK(ctx->f6.d); NAN_CHECK(ctx->f18.d); 
    ctx->f16.d = ctx->f6.d + ctx->f18.d;
    // 0x8004789C: trunc.w.d   $f8, $f16
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 16);
    ctx->f8.u32l = TRUNC_W_D(ctx->f16.d);
    // 0x800478A0: mfc1        $a0, $f8
    ctx->r4 = (int32_t)ctx->f8.u32l;
    // 0x800478A4: nop

    // 0x800478A8: sll         $a0, $a0, 16
    ctx->r4 = S32(ctx->r4 << 16);
    // 0x800478AC: sra         $a0, $a0, 16
    ctx->r4 = S32(SIGNED(ctx->r4) >> 16);
    // 0x800478B0: mtc1        $a0, $f4
    ctx->f4.u32l = ctx->r4;
    // 0x800478B4: addu        $v0, $t6, $a0
    ctx->r2 = ADD32(ctx->r14, ctx->r4);
    // 0x800478B8: sll         $v0, $v0, 16
    ctx->r2 = S32(ctx->r2 << 16);
    // 0x800478BC: cvt.d.w     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.d = CVT_D_W(ctx->f4.u32l);
    // 0x800478C0: sub.d       $f8, $f16, $f6
    CHECK_FR(ctx, 8);
    CHECK_FR(ctx, 16);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f16.d); NAN_CHECK(ctx->f6.d); 
    ctx->f8.d = ctx->f16.d - ctx->f6.d;
    // 0x800478C4: mul.d       $f4, $f10, $f8
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 10);
    CHECK_FR(ctx, 8);
    NAN_CHECK(ctx->f10.d); NAN_CHECK(ctx->f8.d); 
    ctx->f4.d = MUL_D(ctx->f10.d, ctx->f8.d);
    // 0x800478C8: cfc1        $t1, $FpcCsr
    ctx->r9 = get_cop1_cs();
    // 0x800478CC: ctc1        $t2, $FpcCsr
    set_cop1_cs(ctx->r10);
    // 0x800478D0: nop

    // 0x800478D4: cvt.w.d     $f6, $f4
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    ctx->f6.u32l = CVT_W_D(ctx->f4.d);
    // 0x800478D8: cfc1        $t2, $FpcCsr
    ctx->r10 = get_cop1_cs();
    // 0x800478DC: nop

    // 0x800478E0: andi        $t2, $t2, 0x78
    ctx->r10 = ctx->r10 & 0X78;
    // 0x800478E4: beql        $t2, $zero, L_80047938
    if (ctx->r10 == 0) {
        // 0x800478E8: mfc1        $t2, $f6
        ctx->r10 = (int32_t)ctx->f6.u32l;
            goto L_80047938;
    }
    goto skip_2;
    // 0x800478E8: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
    skip_2:
    // 0x800478EC: mtc1        $at, $f7
    ctx->f_odd[(7 - 1) * 2] = ctx->r1;
    // 0x800478F0: mtc1        $zero, $f6
    ctx->f6.u32l = 0;
    // 0x800478F4: addiu       $t2, $zero, 0x1
    ctx->r10 = ADD32(0, 0X1);
    // 0x800478F8: sub.d       $f6, $f4, $f6
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 4);
    CHECK_FR(ctx, 6);
    NAN_CHECK(ctx->f4.d); NAN_CHECK(ctx->f6.d); 
    ctx->f6.d = ctx->f4.d - ctx->f6.d;
    // 0x800478FC: ctc1        $t2, $FpcCsr
    set_cop1_cs(ctx->r10);
    // 0x80047900: nop

    // 0x80047904: cvt.w.d     $f6, $f6
    CHECK_FR(ctx, 6);
    CHECK_FR(ctx, 6);
    ctx->f6.u32l = CVT_W_D(ctx->f6.d);
    // 0x80047908: cfc1        $t2, $FpcCsr
    ctx->r10 = get_cop1_cs();
    // 0x8004790C: nop

    // 0x80047910: andi        $t2, $t2, 0x78
    ctx->r10 = ctx->r10 & 0X78;
    // 0x80047914: bne         $t2, $zero, L_8004792C
    if (ctx->r10 != 0) {
        // 0x80047918: nop
    
            goto L_8004792C;
    }
    // 0x80047918: nop

    // 0x8004791C: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
    // 0x80047920: lui         $at, 0x8000
    ctx->r1 = S32(0X8000 << 16);
    // 0x80047924: b           L_80047944
    // 0x80047928: or          $t2, $t2, $at
    ctx->r10 = ctx->r10 | ctx->r1;
        goto L_80047944;
    // 0x80047928: or          $t2, $t2, $at
    ctx->r10 = ctx->r10 | ctx->r1;
L_8004792C:
    // 0x8004792C: b           L_80047944
    // 0x80047930: addiu       $t2, $zero, -0x1
    ctx->r10 = ADD32(0, -0X1);
        goto L_80047944;
    // 0x80047930: addiu       $t2, $zero, -0x1
    ctx->r10 = ADD32(0, -0X1);
    // 0x80047934: mfc1        $t2, $f6
    ctx->r10 = (int32_t)ctx->f6.u32l;
L_80047938:
    // 0x80047938: nop

    // 0x8004793C: bltz        $t2, L_8004792C
    if (SIGNED(ctx->r10) < 0) {
        // 0x80047940: nop
    
            goto L_8004792C;
    }
    // 0x80047940: nop

L_80047944:
    // 0x80047944: ctc1        $t1, $FpcCsr
    set_cop1_cs(ctx->r9);
    // 0x80047948: sh          $t2, 0x0($t3)
    MEM_H(0X0, ctx->r11) = ctx->r10;
    // 0x8004794C: sra         $v0, $v0, 16
    ctx->r2 = S32(SIGNED(ctx->r2) >> 16);
    // 0x80047950: jr          $ra
    // 0x80047954: nop

    return;
    // 0x80047954: nop

;}
