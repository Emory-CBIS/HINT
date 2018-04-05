/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * UpdateThetaBetaAprx_LargeData_emxAPI.h
 *
 * Code generation for function 'UpdateThetaBetaAprx_LargeData_emxAPI'
 *
 */

#ifndef UPDATETHETABETAAPRX_LARGEDATA_EMXAPI_H
#define UPDATETHETABETAAPRX_LARGEDATA_EMXAPI_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern emxArray_real_T *emxCreateND_real_T(int numDimensions, int *size);
extern emxArray_real_T *emxCreateWrapperND_real_T(double *data, int
  numDimensions, int *size);
extern emxArray_real_T *emxCreateWrapper_real_T(double *data, int rows, int cols);
extern emxArray_real_T *emxCreate_real_T(int rows, int cols);
extern void emxDestroyArray_real_T(emxArray_real_T *emxArray);
extern void emxDestroy_struct1_T(struct1_T emxArray);
extern void emxInitArray_real_T(emxArray_real_T **pEmxArray, int numDimensions);
extern void emxInit_struct1_T(struct1_T *pStruct);

#endif

/* End of code generation (UpdateThetaBetaAprx_LargeData_emxAPI.h) */
