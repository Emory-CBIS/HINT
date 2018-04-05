/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_UpdateThetaBetaAprx_LargeData_api.c
 *
 * Code generation for function '_coder_UpdateThetaBetaAprx_LargeData_api'
 *
 */

/* Include files */
#include "tmwtypes.h"
#include "_coder_UpdateThetaBetaAprx_LargeData_api.h"
#include "_coder_UpdateThetaBetaAprx_LargeData_mex.h"

/* Type Definitions */
#ifndef struct_emxArray__common
#define struct_emxArray__common

struct emxArray__common
{
  void *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};

#endif                                 /*struct_emxArray__common*/

#ifndef typedef_emxArray__common
#define typedef_emxArray__common

typedef struct emxArray__common emxArray__common;

#endif                                 /*typedef_emxArray__common*/

/* Variable Definitions */
emlrtCTX emlrtRootTLSGlobal = NULL;
emlrtContext emlrtContextGlobal = { true,/* bFirstTime */
  false,                               /* bInitialized */
  131450U,                             /* fVersionInfo */
  NULL,                                /* fErrorFunction */
  "UpdateThetaBetaAprx_LargeData",     /* fFunctionName */
  NULL,                                /* fRTCallStack */
  false,                               /* bDebugMode */
  { 2045744189U, 2170104910U, 2743257031U, 4284093946U },/* fSigWrd */
  NULL                                 /* fSigMem */
};

/* Function Declarations */
static real_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[304800];
static const mxArray *b_emlrt_marshallOut(const real_T u);
static real_T (*c_emlrt_marshallIn(const mxArray *X_mtx, const char_T
  *identifier))[40];
static const mxArray *c_emlrt_marshallOut(const emxArray_real_T *u);
static real_T (*d_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[40];
static const mxArray *d_emlrt_marshallOut(const emxArray_real_T *u);
static void e_emlrt_marshallIn(const mxArray *theta, const char_T *identifier,
  struct0_T *y);
static const mxArray *e_emlrt_marshallOut(const emxArray_real_T *u);
static real_T (*emlrt_marshallIn(const mxArray *Y, const char_T *identifier))
  [304800];
static const mxArray *emlrt_marshallOut(const struct1_T u);
static void emxEnsureCapacity(emxArray__common *emxArray, int32_T oldNumel,
  uint32_T elementSize);
static void emxFreeStruct_struct1_T(struct1_T *pStruct);
static void emxFree_real_T(emxArray_real_T **pEmxArray);
static void emxInitStruct_struct1_T(struct1_T *pStruct, boolean_T doPush);
static void emxInit_real_T(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush);
static void emxInit_real_T1(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush);
static void emxInit_real_T2(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush);
static void emxInit_real_T3(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush);
static void f_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, struct0_T *y);
static const mxArray *f_emlrt_marshallOut(const emxArray_real_T *u);
static void g_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[6]);
static real_T h_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId);
static void i_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[3]);
static void j_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[180]);
static real32_T (*k_emlrt_marshallIn(const mxArray *C_matrix_diag, const char_T *
  identifier))[60];
static real32_T (*l_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier *
  parentId))[60];
static real_T (*m_emlrt_marshallIn(const mxArray *beta, const char_T *identifier))
  [30480];
static real_T (*n_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[30480];
static real_T o_emlrt_marshallIn(const mxArray *N, const char_T *identifier);
static real_T (*p_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[304800];
static real_T (*q_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[40];
static void r_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[6]);
static real_T s_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId);
static void t_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[3]);
static void u_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[180]);
static real32_T (*v_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[60];
static real_T (*w_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[30480];

/* Function Definitions */
static real_T (*b_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[304800]
{
  real_T (*y)[304800];
  y = p_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}
  static const mxArray *b_emlrt_marshallOut(const real_T u)
{
  const mxArray *y;
  const mxArray *m1;
  y = NULL;
  m1 = emlrtCreateDoubleScalar(u);
  emlrtAssign(&y, m1);
  return y;
}

static real_T (*c_emlrt_marshallIn(const mxArray *X_mtx, const char_T
  *identifier))[40]
{
  real_T (*y)[40];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = d_emlrt_marshallIn(emlrtAlias(X_mtx), &thisId);
  emlrtDestroyArray(&X_mtx);
  return y;
}
  static const mxArray *c_emlrt_marshallOut(const emxArray_real_T *u)
{
  const mxArray *y;
  const mxArray *m2;
  static const int32_T iv0[3] = { 0, 0, 0 };

  y = NULL;
  m2 = emlrtCreateNumericArray(3, iv0, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m2, (void *)&u->data[0]);
  emlrtSetDimensions((mxArray *)m2, u->size, 3);
  emlrtAssign(&y, m2);
  return y;
}

static real_T (*d_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId))[40]
{
  real_T (*y)[40];
  y = q_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}
  static const mxArray *d_emlrt_marshallOut(const emxArray_real_T *u)
{
  const mxArray *y;
  const mxArray *m3;
  static const int32_T iv1[1] = { 0 };

  y = NULL;
  m3 = emlrtCreateNumericArray(1, iv1, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m3, (void *)&u->data[0]);
  emlrtSetDimensions((mxArray *)m3, u->size, 1);
  emlrtAssign(&y, m3);
  return y;
}

static void e_emlrt_marshallIn(const mxArray *theta, const char_T *identifier,
  struct0_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  f_emlrt_marshallIn(emlrtAlias(theta), &thisId, y);
  emlrtDestroyArray(&theta);
}

static const mxArray *e_emlrt_marshallOut(const emxArray_real_T *u)
{
  const mxArray *y;
  const mxArray *m4;
  static const int32_T iv2[4] = { 0, 0, 0, 0 };

  y = NULL;
  m4 = emlrtCreateNumericArray(4, iv2, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m4, (void *)&u->data[0]);
  emlrtSetDimensions((mxArray *)m4, u->size, 4);
  emlrtAssign(&y, m4);
  return y;
}

static real_T (*emlrt_marshallIn(const mxArray *Y, const char_T *identifier))
  [304800]
{
  real_T (*y)[304800];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = b_emlrt_marshallIn(emlrtAlias(Y), &thisId);
  emlrtDestroyArray(&Y);
  return y;
}
  static const mxArray *emlrt_marshallOut(const struct1_T u)
{
  const mxArray *y;
  emxArray_real_T *b_u;
  int32_T i0;
  int32_T loop_ub;
  const mxArray *b_y;
  const mxArray *m0;
  real_T *pData;
  emxArray_real_T *c_u;
  int32_T i;
  int32_T b_i;
  emlrtHeapReferenceStackEnterFcnR2012b(emlrtRootTLSGlobal);
  emxInit_real_T(&b_u, 3, true);
  y = NULL;
  emlrtAssign(&y, emlrtCreateStructMatrix(1, 1, 0, NULL));
  i0 = b_u->size[0] * b_u->size[1] * b_u->size[2];
  b_u->size[0] = u.A->size[0];
  b_u->size[1] = u.A->size[1];
  b_u->size[2] = u.A->size[2];
  emxEnsureCapacity((emxArray__common *)b_u, i0, sizeof(real_T));
  loop_ub = u.A->size[0] * u.A->size[1] * u.A->size[2];
  for (i0 = 0; i0 < loop_ub; i0++) {
    b_u->data[i0] = u.A->data[i0];
  }

  b_y = NULL;
  m0 = emlrtCreateNumericArray(3, *(int32_T (*)[3])b_u->size, mxDOUBLE_CLASS,
    mxREAL);
  pData = (real_T *)mxGetPr(m0);
  i0 = 0;
  loop_ub = 0;
  emxFree_real_T(&b_u);
  while (loop_ub < u.A->size[2]) {
    for (i = 0; i < u.A->size[1]; i++) {
      for (b_i = 0; b_i < u.A->size[0]; b_i++) {
        pData[i0] = u.A->data[(b_i + u.A->size[0] * i) + u.A->size[0] *
          u.A->size[1] * loop_ub];
        i0++;
      }
    }

    loop_ub++;
  }

  emxInit_real_T1(&c_u, 1, true);
  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "A", 0);
  emlrtAddField(y, b_emlrt_marshallOut(u.sigma1_sq), "sigma1_sq", 0);
  i0 = c_u->size[0];
  c_u->size[0] = u.sigma2_sq->size[0];
  emxEnsureCapacity((emxArray__common *)c_u, i0, sizeof(real_T));
  loop_ub = u.sigma2_sq->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    c_u->data[i0] = u.sigma2_sq->data[i0];
  }

  b_y = NULL;
  m0 = emlrtCreateNumericArray(1, *(int32_T (*)[3])c_u->size, mxDOUBLE_CLASS,
    mxREAL);
  pData = (real_T *)mxGetPr(m0);
  i0 = 0;
  for (loop_ub = 0; loop_ub < u.sigma2_sq->size[0]; loop_ub++) {
    pData[i0] = u.sigma2_sq->data[loop_ub];
    i0++;
  }

  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "sigma2_sq", 0);
  i0 = c_u->size[0];
  c_u->size[0] = u.miu3->size[0];
  emxEnsureCapacity((emxArray__common *)c_u, i0, sizeof(real_T));
  loop_ub = u.miu3->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    c_u->data[i0] = u.miu3->data[i0];
  }

  b_y = NULL;
  m0 = emlrtCreateNumericArray(1, *(int32_T (*)[3])c_u->size, mxDOUBLE_CLASS,
    mxREAL);
  pData = (real_T *)mxGetPr(m0);
  i0 = 0;
  for (loop_ub = 0; loop_ub < u.miu3->size[0]; loop_ub++) {
    pData[i0] = u.miu3->data[loop_ub];
    i0++;
  }

  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "miu3", 0);
  i0 = c_u->size[0];
  c_u->size[0] = u.sigma3_sq->size[0];
  emxEnsureCapacity((emxArray__common *)c_u, i0, sizeof(real_T));
  loop_ub = u.sigma3_sq->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    c_u->data[i0] = u.sigma3_sq->data[i0];
  }

  b_y = NULL;
  m0 = emlrtCreateNumericArray(1, *(int32_T (*)[3])c_u->size, mxDOUBLE_CLASS,
    mxREAL);
  pData = (real_T *)mxGetPr(m0);
  i0 = 0;
  for (loop_ub = 0; loop_ub < u.sigma3_sq->size[0]; loop_ub++) {
    pData[i0] = u.sigma3_sq->data[loop_ub];
    i0++;
  }

  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "sigma3_sq", 0);
  i0 = c_u->size[0];
  c_u->size[0] = u.pi->size[0];
  emxEnsureCapacity((emxArray__common *)c_u, i0, sizeof(real_T));
  loop_ub = u.pi->size[0];
  for (i0 = 0; i0 < loop_ub; i0++) {
    c_u->data[i0] = u.pi->data[i0];
  }

  b_y = NULL;
  m0 = emlrtCreateNumericArray(1, *(int32_T (*)[3])c_u->size, mxDOUBLE_CLASS,
    mxREAL);
  pData = (real_T *)mxGetPr(m0);
  i0 = 0;
  loop_ub = 0;
  emxFree_real_T(&c_u);
  while (loop_ub < u.pi->size[0]) {
    pData[i0] = u.pi->data[loop_ub];
    i0++;
    loop_ub++;
  }

  emlrtAssign(&b_y, m0);
  emlrtAddField(y, b_y, "pi", 0);
  emlrtHeapReferenceStackLeaveFcnR2012b(emlrtRootTLSGlobal);
  return y;
}

static void emxEnsureCapacity(emxArray__common *emxArray, int32_T oldNumel,
  uint32_T elementSize)
{
  int32_T newNumel;
  int32_T i;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }

  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }

  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }

    while (i < newNumel) {
      if (i > 1073741823) {
        i = MAX_int32_T;
      } else {
        i <<= 1;
      }
    }

    newData = emlrtCallocMex((uint32_T)i, elementSize);
    if (emxArray->data != NULL) {
      memcpy(newData, emxArray->data, elementSize * oldNumel);
      if (emxArray->canFreeData) {
        emlrtFreeMex(emxArray->data);
      }
    }

    emxArray->data = newData;
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

static void emxFreeStruct_struct1_T(struct1_T *pStruct)
{
  emxFree_real_T(&pStruct->A);
  emxFree_real_T(&pStruct->sigma2_sq);
  emxFree_real_T(&pStruct->miu3);
  emxFree_real_T(&pStruct->sigma3_sq);
  emxFree_real_T(&pStruct->pi);
}

static void emxFree_real_T(emxArray_real_T **pEmxArray)
{
  if (*pEmxArray != (emxArray_real_T *)NULL) {
    if (((*pEmxArray)->data != (real_T *)NULL) && (*pEmxArray)->canFreeData) {
      emlrtFreeMex((void *)(*pEmxArray)->data);
    }

    emlrtFreeMex((void *)(*pEmxArray)->size);
    emlrtFreeMex((void *)*pEmxArray);
    *pEmxArray = (emxArray_real_T *)NULL;
  }
}

static void emxInitStruct_struct1_T(struct1_T *pStruct, boolean_T doPush)
{
  emxInit_real_T(&pStruct->A, 3, doPush);
  emxInit_real_T1(&pStruct->sigma2_sq, 1, doPush);
  emxInit_real_T1(&pStruct->miu3, 1, doPush);
  emxInit_real_T1(&pStruct->sigma3_sq, 1, doPush);
  emxInit_real_T1(&pStruct->pi, 1, doPush);
}

static void emxInit_real_T(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush)
{
  emxArray_real_T *emxArray;
  int32_T i;
  *pEmxArray = (emxArray_real_T *)emlrtMallocMex(sizeof(emxArray_real_T));
  if (doPush) {
    emlrtPushHeapReferenceStackR2012b(emlrtRootTLSGlobal, (void *)pEmxArray,
      (void (*)(void *))emxFree_real_T);
  }

  emxArray = *pEmxArray;
  emxArray->data = (real_T *)NULL;
  emxArray->numDimensions = numDimensions;
  emxArray->size = (int32_T *)emlrtMallocMex((uint32_T)(sizeof(int32_T)
    * numDimensions));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (i = 0; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

static void emxInit_real_T1(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush)
{
  emxArray_real_T *emxArray;
  int32_T i;
  *pEmxArray = (emxArray_real_T *)emlrtMallocMex(sizeof(emxArray_real_T));
  if (doPush) {
    emlrtPushHeapReferenceStackR2012b(emlrtRootTLSGlobal, (void *)pEmxArray,
      (void (*)(void *))emxFree_real_T);
  }

  emxArray = *pEmxArray;
  emxArray->data = (real_T *)NULL;
  emxArray->numDimensions = numDimensions;
  emxArray->size = (int32_T *)emlrtMallocMex((uint32_T)(sizeof(int32_T)
    * numDimensions));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (i = 0; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

static void emxInit_real_T2(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush)
{
  emxArray_real_T *emxArray;
  int32_T i;
  *pEmxArray = (emxArray_real_T *)emlrtMallocMex(sizeof(emxArray_real_T));
  if (doPush) {
    emlrtPushHeapReferenceStackR2012b(emlrtRootTLSGlobal, (void *)pEmxArray,
      (void (*)(void *))emxFree_real_T);
  }

  emxArray = *pEmxArray;
  emxArray->data = (real_T *)NULL;
  emxArray->numDimensions = numDimensions;
  emxArray->size = (int32_T *)emlrtMallocMex((uint32_T)(sizeof(int32_T)
    * numDimensions));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (i = 0; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

static void emxInit_real_T3(emxArray_real_T **pEmxArray, int32_T numDimensions,
  boolean_T doPush)
{
  emxArray_real_T *emxArray;
  int32_T i;
  *pEmxArray = (emxArray_real_T *)emlrtMallocMex(sizeof(emxArray_real_T));
  if (doPush) {
    emlrtPushHeapReferenceStackR2012b(emlrtRootTLSGlobal, (void *)pEmxArray,
      (void (*)(void *))emxFree_real_T);
  }

  emxArray = *pEmxArray;
  emxArray->data = (real_T *)NULL;
  emxArray->numDimensions = numDimensions;
  emxArray->size = (int32_T *)emlrtMallocMex((uint32_T)(sizeof(int32_T)
    * numDimensions));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  for (i = 0; i < numDimensions; i++) {
    emxArray->size[i] = 0;
  }
}

static void f_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, struct0_T *y)
{
  emlrtMsgIdentifier thisId;
  static const char * fieldNames[6] = { "miu3", "sigma3_sq", "pi", "sigma1_sq",
    "sigma2_sq", "A" };

  static const int32_T dims = 0;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b(emlrtRootTLSGlobal, parentId, u, 6, fieldNames, 0U,
    &dims);
  thisId.fIdentifier = "miu3";
  g_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a(emlrtRootTLSGlobal, u, 0,
    "miu3")), &thisId, y->miu3);
  thisId.fIdentifier = "sigma3_sq";
  g_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a(emlrtRootTLSGlobal, u, 0,
    "sigma3_sq")), &thisId, y->sigma3_sq);
  thisId.fIdentifier = "pi";
  g_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a(emlrtRootTLSGlobal, u, 0,
    "pi")), &thisId, y->pi);
  thisId.fIdentifier = "sigma1_sq";
  y->sigma1_sq = h_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a
    (emlrtRootTLSGlobal, u, 0, "sigma1_sq")), &thisId);
  thisId.fIdentifier = "sigma2_sq";
  i_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a(emlrtRootTLSGlobal, u, 0,
    "sigma2_sq")), &thisId, y->sigma2_sq);
  thisId.fIdentifier = "A";
  j_emlrt_marshallIn(emlrtAlias(emlrtGetFieldR2013a(emlrtRootTLSGlobal, u, 0,
    "A")), &thisId, y->A);
  emlrtDestroyArray(&u);
}

static const mxArray *f_emlrt_marshallOut(const emxArray_real_T *u)
{
  const mxArray *y;
  const mxArray *m5;
  static const int32_T iv3[2] = { 0, 0 };

  y = NULL;
  m5 = emlrtCreateNumericArray(2, iv3, mxDOUBLE_CLASS, mxREAL);
  mxSetData((mxArray *)m5, (void *)&u->data[0]);
  emlrtSetDimensions((mxArray *)m5, u->size, 2);
  emlrtAssign(&y, m5);
  return y;
}

static void g_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[6])
{
  r_emlrt_marshallIn(emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

static real_T h_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId)
{
  real_T y;
  y = s_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static void i_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[3])
{
  t_emlrt_marshallIn(emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

static void j_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier
  *parentId, real_T y[180])
{
  u_emlrt_marshallIn(emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

static real32_T (*k_emlrt_marshallIn(const mxArray *C_matrix_diag, const char_T *
  identifier))[60]
{
  real32_T (*y)[60];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = l_emlrt_marshallIn(emlrtAlias(C_matrix_diag), &thisId);
  emlrtDestroyArray(&C_matrix_diag);
  return y;
}
  static real32_T (*l_emlrt_marshallIn(const mxArray *u, const
  emlrtMsgIdentifier *parentId))[60]
{
  real32_T (*y)[60];
  y = v_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T (*m_emlrt_marshallIn(const mxArray *beta, const char_T *identifier))
  [30480]
{
  real_T (*y)[30480];
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = n_emlrt_marshallIn(emlrtAlias(beta), &thisId);
  emlrtDestroyArray(&beta);
  return y;
}
  static real_T (*n_emlrt_marshallIn(const mxArray *u, const emlrtMsgIdentifier *
  parentId))[30480]
{
  real_T (*y)[30480];
  y = w_emlrt_marshallIn(emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

static real_T o_emlrt_marshallIn(const mxArray *N, const char_T *identifier)
{
  real_T y;
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = h_emlrt_marshallIn(emlrtAlias(N), &thisId);
  emlrtDestroyArray(&N);
  return y;
}

static real_T (*p_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier *
  msgId))[304800]
{
  real_T (*ret)[304800];
  static const int32_T dims[2] = { 60, 5080 };

  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 2U,
    dims);
  ret = (real_T (*)[304800])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}
  static real_T (*q_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[40]
{
  real_T (*ret)[40];
  static const int32_T dims[2] = { 2, 20 };

  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 2U,
    dims);
  ret = (real_T (*)[40])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static void r_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[6])
{
  static const int32_T dims[1] = { 6 };

  int32_T i1;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 1U,
    dims);
  for (i1 = 0; i1 < 6; i1++) {
    ret[i1] = (*(real_T (*)[6])mxGetData(src))[i1];
  }

  emlrtDestroyArray(&src);
}

static real_T s_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId)
{
  real_T ret;
  static const int32_T dims = 0;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 0U,
    &dims);
  ret = *(real_T *)mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

static void t_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[3])
{
  static const int32_T dims[1] = { 3 };

  int32_T i2;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 1U,
    dims);
  for (i2 = 0; i2 < 3; i2++) {
    ret[i2] = (*(real_T (*)[3])mxGetData(src))[i2];
  }

  emlrtDestroyArray(&src);
}

static void u_emlrt_marshallIn(const mxArray *src, const emlrtMsgIdentifier
  *msgId, real_T ret[180])
{
  static const int32_T dims[3] = { 3, 3, 20 };

  int32_T i3;
  int32_T i4;
  int32_T i5;
  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 3U,
    dims);
  for (i3 = 0; i3 < 20; i3++) {
    for (i4 = 0; i4 < 3; i4++) {
      for (i5 = 0; i5 < 3; i5++) {
        ret[(i5 + 3 * i4) + 9 * i3] = (*(real_T (*)[180])mxGetData(src))[(i5 + 3
          * i4) + 9 * i3];
      }
    }
  }

  emlrtDestroyArray(&src);
}

static real32_T (*v_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[60]
{
  real32_T (*ret)[60];
  static const int32_T dims[1] = { 60 };

  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "single", false, 1U,
    dims);
  ret = (real32_T (*)[60])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}
  static real_T (*w_emlrt_marshallIn(const mxArray *src, const
  emlrtMsgIdentifier *msgId))[30480]
{
  real_T (*ret)[30480];
  static const int32_T dims[3] = { 2, 3, 5080 };

  emlrtCheckBuiltInR2012b(emlrtRootTLSGlobal, msgId, src, "double", false, 3U,
    dims);
  ret = (real_T (*)[30480])mxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

void UpdateThetaBetaAprx_LargeData_api(const mxArray * const prhs[11], const
  mxArray *plhs[9])
{
  struct1_T theta_new;
  emxArray_real_T *beta_new;
  emxArray_real_T *z_mode;
  emxArray_real_T *subICmean;
  emxArray_real_T *subICvar;
  emxArray_real_T *grpICmean;
  emxArray_real_T *grpICvar;
  emxArray_real_T *G_z_dict;
  real_T (*Y)[304800];
  real_T (*X_mtx)[40];
  struct0_T theta;
  real32_T (*C_matrix_diag)[60];
  real_T (*beta)[30480];
  real_T N;
  real_T T;
  real_T q;
  real_T p;
  real_T m;
  real_T V;
  real_T err;
  emlrtHeapReferenceStackEnterFcnR2012b(emlrtRootTLSGlobal);
  emxInitStruct_struct1_T(&theta_new, true);
  emxInit_real_T(&beta_new, 3, true);
  emxInit_real_T1(&z_mode, 1, true);
  emxInit_real_T(&subICmean, 3, true);
  emxInit_real_T2(&subICvar, 4, true);
  emxInit_real_T3(&grpICmean, 2, true);
  emxInit_real_T(&grpICvar, 3, true);
  emxInit_real_T(&G_z_dict, 3, true);

  /* Marshall function inputs */
  Y = emlrt_marshallIn(emlrtAlias(prhs[0]), "Y");
  X_mtx = c_emlrt_marshallIn(emlrtAlias(prhs[1]), "X_mtx");
  e_emlrt_marshallIn(emlrtAliasP(prhs[2]), "theta", &theta);
  C_matrix_diag = k_emlrt_marshallIn(emlrtAlias(prhs[3]), "C_matrix_diag");
  beta = m_emlrt_marshallIn(emlrtAlias(prhs[4]), "beta");
  N = o_emlrt_marshallIn(emlrtAliasP(prhs[5]), "N");
  T = o_emlrt_marshallIn(emlrtAliasP(prhs[6]), "T");
  q = o_emlrt_marshallIn(emlrtAliasP(prhs[7]), "q");
  p = o_emlrt_marshallIn(emlrtAliasP(prhs[8]), "p");
  m = o_emlrt_marshallIn(emlrtAliasP(prhs[9]), "m");
  V = o_emlrt_marshallIn(emlrtAliasP(prhs[10]), "V");

  /* Invoke the target function */
  UpdateThetaBetaAprx_LargeData(*Y, *X_mtx, &theta, *C_matrix_diag, *beta, N, T,
    q, p, m, V, &theta_new, beta_new, z_mode, subICmean, subICvar, grpICmean,
    grpICvar, &err, G_z_dict);

  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(theta_new);
  plhs[1] = c_emlrt_marshallOut(beta_new);
  plhs[2] = d_emlrt_marshallOut(z_mode);
  plhs[3] = c_emlrt_marshallOut(subICmean);
  plhs[4] = e_emlrt_marshallOut(subICvar);
  plhs[5] = f_emlrt_marshallOut(grpICmean);
  plhs[6] = c_emlrt_marshallOut(grpICvar);
  plhs[7] = b_emlrt_marshallOut(err);
  plhs[8] = c_emlrt_marshallOut(G_z_dict);
  G_z_dict->canFreeData = false;
  emxFree_real_T(&G_z_dict);
  grpICvar->canFreeData = false;
  emxFree_real_T(&grpICvar);
  grpICmean->canFreeData = false;
  emxFree_real_T(&grpICmean);
  subICvar->canFreeData = false;
  emxFree_real_T(&subICvar);
  subICmean->canFreeData = false;
  emxFree_real_T(&subICmean);
  z_mode->canFreeData = false;
  emxFree_real_T(&z_mode);
  beta_new->canFreeData = false;
  emxFree_real_T(&beta_new);
  emxFreeStruct_struct1_T(&theta_new);
  emlrtHeapReferenceStackLeaveFcnR2012b(emlrtRootTLSGlobal);
}

void UpdateThetaBetaAprx_LargeData_atexit(void)
{
  mexFunctionCreateRootTLS();
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
  UpdateThetaBetaAprx_LargeData_xil_terminate();
}

void UpdateThetaBetaAprx_LargeData_initialize(void)
{
  mexFunctionCreateRootTLS();
  emlrtClearAllocCountR2012b(emlrtRootTLSGlobal, false, 0U, 0);
  emlrtEnterRtStackR2012b(emlrtRootTLSGlobal);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

void UpdateThetaBetaAprx_LargeData_terminate(void)
{
  emlrtLeaveRtStackR2012b(emlrtRootTLSGlobal);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/* End of code generation (_coder_UpdateThetaBetaAprx_LargeData_api.c) */
