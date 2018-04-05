/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_UpdateThetaBetaAprx_LargeData_api.h
 *
 * Code generation for function '_coder_UpdateThetaBetaAprx_LargeData_api'
 *
 */

#ifndef _CODER_UPDATETHETABETAAPRX_LARGEDATA_API_H
#define _CODER_UPDATETHETABETAAPRX_LARGEDATA_API_H

/* Include files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_UpdateThetaBetaAprx_LargeData_api.h"

/* Type Definitions */
#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T

struct emxArray_real_T
{
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};

#endif                                 /*struct_emxArray_real_T*/

#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T

typedef struct emxArray_real_T emxArray_real_T;

#endif                                 /*typedef_emxArray_real_T*/

#ifndef typedef_struct0_T
#define typedef_struct0_T

typedef struct {
  real_T miu3[6];
  real_T sigma3_sq[6];
  real_T pi[6];
  real_T sigma1_sq;
  real_T sigma2_sq[3];
  real_T A[180];
} struct0_T;

#endif                                 /*typedef_struct0_T*/

#ifndef typedef_struct1_T
#define typedef_struct1_T

typedef struct {
  emxArray_real_T *A;
  real_T sigma1_sq;
  emxArray_real_T *sigma2_sq;
  emxArray_real_T *miu3;
  emxArray_real_T *sigma3_sq;
  emxArray_real_T *pi;
} struct1_T;

#endif                                 /*typedef_struct1_T*/

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern void UpdateThetaBetaAprx_LargeData(real_T Y[304800], real_T X_mtx[40],
  struct0_T *theta, real32_T C_matrix_diag[60], real_T beta[30480], real_T N,
  real_T T, real_T q, real_T p, real_T m, real_T V, struct1_T *theta_new,
  emxArray_real_T *beta_new, emxArray_real_T *z_mode, emxArray_real_T *subICmean,
  emxArray_real_T *subICvar, emxArray_real_T *grpICmean, emxArray_real_T
  *grpICvar, real_T *err, emxArray_real_T *G_z_dict);
extern void UpdateThetaBetaAprx_LargeData_api(const mxArray * const prhs[11],
  const mxArray *plhs[9]);
extern void UpdateThetaBetaAprx_LargeData_atexit(void);
extern void UpdateThetaBetaAprx_LargeData_initialize(void);
extern void UpdateThetaBetaAprx_LargeData_terminate(void);
extern void UpdateThetaBetaAprx_LargeData_xil_terminate(void);

#endif

/* End of code generation (_coder_UpdateThetaBetaAprx_LargeData_api.h) */
