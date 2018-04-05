/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * diag.h
 *
 * Code generation for function 'diag'
 *
 */

#ifndef DIAG_H
#define DIAG_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void b_diag(const float v[3600], float d[60]);
extern void c_diag(const double v[3], double d[9]);
extern void d_diag(const emxArray_real_T *v, emxArray_real_T *d);
extern void diag(const float v[60], float d[3600]);
extern void e_diag(const emxArray_real_T *v, emxArray_real_T *d);

#endif

/* End of code generation (diag.h) */
