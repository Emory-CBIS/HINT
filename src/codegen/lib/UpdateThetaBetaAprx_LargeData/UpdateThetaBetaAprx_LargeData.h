/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * UpdateThetaBetaAprx_LargeData.h
 *
 * Code generation for function 'UpdateThetaBetaAprx_LargeData'
 *
 */

#ifndef UPDATETHETABETAAPRX_LARGEDATA_H
#define UPDATETHETABETAAPRX_LARGEDATA_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void UpdateThetaBetaAprx_LargeData(const double Y[304800], const double
  X_mtx[40], const struct0_T *theta, const float C_matrix_diag[60], const double
  beta[30480], double N, double T, double q, double p, double m, double V,
  struct1_T *theta_new, emxArray_real_T *beta_new, emxArray_real_T *z_mode,
  emxArray_real_T *subICmean, emxArray_real_T *subICvar, emxArray_real_T
  *grpICmean, emxArray_real_T *grpICvar, double *err, emxArray_real_T *G_z_dict);

#endif

/* End of code generation (UpdateThetaBetaAprx_LargeData.h) */
