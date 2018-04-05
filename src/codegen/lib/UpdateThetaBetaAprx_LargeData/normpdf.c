/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * normpdf.c
 *
 * Code generation for function 'normpdf'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "normpdf.h"

/* Function Definitions */
void normpdf(const emxArray_real_T *x, const float sigma[60], float y[60])
{
  int k;
  float t;
  for (k = 0; k < 60; k++) {
    if (sigma[k] > 0.0F) {
      t = (float)x->data[k] / sigma[k];
      y[k] = (float)exp(-0.5F * t * t) / (2.50662827F * sigma[k]);
    } else {
      y[k] = ((real32_T)rtNaN);
    }
  }
}

/* End of code generation (normpdf.c) */
