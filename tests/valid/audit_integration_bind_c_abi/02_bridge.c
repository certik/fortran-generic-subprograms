extern int fgs_audit_generic_step(int value);

int fgs_audit_call_generic(void)
{
    if (fgs_audit_generic_step(7) != 22) {
        return 1;
    }
    if (fgs_audit_generic_step(-3) != -8) {
        return 2;
    }
    return 0;
}
