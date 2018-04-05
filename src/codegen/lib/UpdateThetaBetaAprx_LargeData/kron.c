/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * kron.c
 *
 * Code generation for function 'kron'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "kron.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void b_kron(const emxArray_real_T *A, const double B[9], emxArray_real_T *K)
{
  int kidx;
  int unnamed_idx_1;
  int j2;
  int i1;
  int i2;
  kidx = A->size[0] * 3;
  unnamed_idx_1 = A->size[1] * 3;
  j2 = K->size[0] * K->size[1];
  K->size[0] = kidx;
  K->size[1] = unnamed_idx_1;
  emxEnsureCapacity((emxArray__common *)K, j2, sizeof(double));
  kidx = -1;
  for (unnamed_idx_1 = 1; unnamed_idx_1 <= A->size[1]; unnamed_idx_1++) {
    for (j2 = 0; j2 < 3; j2++) {
      for (i1 = 1; i1 <= A->size[0]; i1++) {
        for (i2 = 0; i2 < 3; i2++) {
          kidx++;
          K->data[kidx] = A->data[(i1 + A->size[0] * (unnamed_idx_1 - 1)) - 1] *
            B[i2 + 3 * j2];
        }
      }
    }
  }
}

void c_kron(const emxArray_real_T *A, const double B[6], emxArray_real_T *K)
{
  int kidx;
  int unnamed_idx_1;
  int j2;
  int i1;
  int i2;
  kidx = A->size[0] * 3;
  unnamed_idx_1 = A->size[1] << 1;
  j2 = K->size[0] * K->size[1];
  K->size[0] = kidx;
  K->size[1] = unnamed_idx_1;
  emxEnsureCapacity((emxArray__common *)K, j2, sizeof(double));
  kidx = -1;
  for (unnamed_idx_1 = 1; unnamed_idx_1 <= A->size[1]; unnamed_idx_1++) {
    for (j2 = 0; j2 < 2; j2++) {
      for (i1 = 1; i1 <= A->size[0]; i1++) {
        for (i2 = 0; i2 < 3; i2++) {
          kidx++;
          K->data[kidx] = A->data[(i1 + A->size[0] * (unnamed_idx_1 - 1)) - 1] *
            B[i2 + 3 * j2];
        }
      }
    }
  }
}

void kron(const emxArray_real_T *A, const emxArray_real_T *B, emxArray_real_T *K)
{
  int kidx;
  int unnamed_idx_1;
  int i1;
  int i2;
  kidx = A->size[0] * B->size[0];
  unnamed_idx_1 = B->size[1];
  i1 = K->size[0] * K->size[1];
  K->size[0] = kidx;
  K->size[1] = unnamed_idx_1;
  emxEnsureCapacity((emxArray__common *)K, i1, sizeof(double));
  kidx = -1;
  for (unnamed_idx_1 = 1; unnamed_idx_1 <= B->size[1]; unnamed_idx_1++) {
    for (i1 = 1; i1 <= A->size[0]; i1++) {
      for (i2 = 1; i2 <= B->size[0]; i2++) {
        kidx++;
        K->data[kidx] = B->data[(i2 + B->size[0] * (unnamed_idx_1 - 1)) - 1];
      }
    }
  }
}

/* End of code generation (kron.c) */
