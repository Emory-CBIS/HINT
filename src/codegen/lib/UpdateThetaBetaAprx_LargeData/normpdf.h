/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * normpdf.h
 *
 * Code generation for function 'normpdf'
 *
 */

#ifndef NORMPDF_H
#define NORMPDF_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void normpdf(const emxArray_real_T *x, const float sigma[60], float y[60]);

#endif

/* End of code generation (normpdf.h) */
