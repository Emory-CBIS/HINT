/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * log.c
 *
 * Code generation for function 'log'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "log.h"

/* Function Definitions */
void b_log(emxArray_real_T *x)
{
  int nx;
  int k;
  nx = x->size[0];
  for (k = 0; k + 1 <= nx; k++) {
    x->data[k] = log(x->data[k]);
  }
}

void c_log(float x[60])
{
  int k;
  for (k = 0; k < 60; k++) {
    x[k] = (float)log(x[k]);
  }
}

/* End of code generation (log.c) */
