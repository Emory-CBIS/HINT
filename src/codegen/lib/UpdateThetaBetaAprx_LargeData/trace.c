/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * trace.c
 *
 * Code generation for function 'trace'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "trace.h"

/* Function Definitions */
double trace(const emxArray_real_T *a)
{
  double t;
  int k;
  t = 0.0;
  for (k = 0; k < a->size[0]; k++) {
    t += a->data[k + a->size[0] * k];
  }

  return t;
}

/* End of code generation (trace.c) */
