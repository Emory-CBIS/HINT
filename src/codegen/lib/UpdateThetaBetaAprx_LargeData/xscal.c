/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * xscal.c
 *
 * Code generation for function 'xscal'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "xscal.h"

/* Function Definitions */
void b_xscal(int n, double a, emxArray_real_T *x, int ix0)
{
  int i19;
  int k;
  i19 = (ix0 + n) - 1;
  for (k = ix0; k <= i19; k++) {
    x->data[k - 1] *= a;
  }
}

void xscal(int n, float a, emxArray_real32_T *x, int ix0)
{
  int i17;
  int k;
  i17 = (ix0 + n) - 1;
  for (k = ix0; k <= i17; k++) {
    x->data[k - 1] *= a;
  }
}

/* End of code generation (xscal.c) */
