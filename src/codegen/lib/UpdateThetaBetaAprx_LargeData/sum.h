/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * sum.h
 *
 * Code generation for function 'sum'
 *
 */

#ifndef SUM_H
#define SUM_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern float b_sum(const float x[60]);
extern void c_sum(const emxArray_real_T *x, emxArray_real_T *y);
extern double sum(const emxArray_real_T *x);

#endif

/* End of code generation (sum.h) */
