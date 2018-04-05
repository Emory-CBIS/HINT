/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * blkdiag.c
 *
 * Code generation for function 'blkdiag'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "blkdiag.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void blkdiag(const emxArray_real_T *varargin_1, const emxArray_real_T
             *varargin_2, emxArray_real_T *y)
{
  int unnamed_idx_0;
  int unnamed_idx_1;
  int i6;
  int loop_ub;
  int i7;
  int i8;
  unnamed_idx_0 = varargin_1->size[0] + varargin_2->size[0];
  unnamed_idx_1 = varargin_1->size[1] + varargin_2->size[1];
  i6 = y->size[0] * y->size[1];
  y->size[0] = unnamed_idx_0;
  y->size[1] = unnamed_idx_1;
  emxEnsureCapacity((emxArray__common *)y, i6, sizeof(double));
  unnamed_idx_0 *= unnamed_idx_1;
  for (i6 = 0; i6 < unnamed_idx_0; i6++) {
    y->data[i6] = 0.0;
  }

  if ((varargin_1->size[0] > 0) && (varargin_1->size[1] > 0)) {
    unnamed_idx_0 = varargin_1->size[1];
    for (i6 = 0; i6 < unnamed_idx_0; i6++) {
      loop_ub = varargin_1->size[0];
      for (unnamed_idx_1 = 0; unnamed_idx_1 < loop_ub; unnamed_idx_1++) {
        y->data[unnamed_idx_1 + y->size[0] * i6] = varargin_1->
          data[unnamed_idx_1 + varargin_1->size[0] * i6];
      }
    }
  }

  if ((varargin_2->size[0] > 0) && (varargin_2->size[1] > 0)) {
    i6 = varargin_1->size[0] + varargin_2->size[0];
    if (varargin_1->size[0] + 1 > i6) {
      i6 = 1;
    } else {
      i6 = varargin_1->size[0] + 1;
    }

    unnamed_idx_1 = varargin_1->size[1] + varargin_2->size[1];
    if (varargin_1->size[1] + 1 > unnamed_idx_1) {
      unnamed_idx_1 = 1;
    } else {
      unnamed_idx_1 = varargin_1->size[1] + 1;
    }

    unnamed_idx_0 = varargin_2->size[1];
    for (i7 = 0; i7 < unnamed_idx_0; i7++) {
      loop_ub = varargin_2->size[0];
      for (i8 = 0; i8 < loop_ub; i8++) {
        y->data[((i6 + i8) + y->size[0] * ((unnamed_idx_1 + i7) - 1)) - 1] =
          varargin_2->data[i8 + varargin_2->size[0] * i7];
      }
    }
  }
}

/* End of code generation (blkdiag.c) */
