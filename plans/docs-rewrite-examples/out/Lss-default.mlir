module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %7 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @Lss_pick_$_1, num_captured = 0} : () -> !eco.value 
        %8 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %9 = "eco.int.gt"(%0, %8) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
        %10 = "eco.box"(%9) {_operand_types = [i1]} : (i1) -> !eco.value 
        %11 = "eco.papExtend"(%7, %10) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %12 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %13 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %1 = "eco.call"(%11, %12, %13) <{_operand_types = [!eco.value, i64, i64], callee = @Lss_repeatApply_$_2}> : (!eco.value, i64, i64) -> i64 
        %16 = "eco.papCreate"(%0) {_fast_evaluator = @_tail_mono_inline_0_9$cap, _operand_types = [i64], _result_kind = 1 : i8, arity = 3, function = @_tail_mono_inline_0_9$clo, num_captured = 1, slot_kinds = array<i8: 1>} : (i64) -> !eco.value 
        %18 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %19 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %2 = "eco.papExtend"(%16, %18, %19) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, i64], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 1>} : (!eco.value, i64, i64) -> i64 
        %21 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %22 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Basics_negate_$_6, num_captured = 0} : () -> !eco.value 
        %23 = "eco.construct.list"(%22, %21) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %24 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Lss_lambda_3, num_captured = 0} : () -> !eco.value 
        %25 = "eco.construct.list"(%24, %23) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %26 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Lss_lambda_2, num_captured = 0} : () -> !eco.value 
        %3 = "eco.construct.list"(%26, %25) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %28 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_5_20, num_captured = 0} : () -> !eco.value 
        %30 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %4 = "eco.papExtend"(%28, %30, %3) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, !eco.value], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> i64 
        %32 = "eco.int.add"(%2, %1) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %33 = "eco.int.add"(%32, %4) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %5 = "eco.string.from_int"(%33) {_operand_types = [i64]} : (i64) -> !eco.value 
        %35 = "eco.call"(%5) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%35) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Lss_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%flag: !eco.value, %_eta0: i64):
        %2 = "eco.unbox"(%flag) {_operand_types = [!eco.value]} : (!eco.value) -> i1 
        %9 = "eco.case"(%2) ({
              %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
              %5 = "eco.int.add"(%_eta0, %4) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
              "eco.yield"(%5) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %7 = "arith.constant"() {value = 2 : i64} : () -> i64 
              %8 = "eco.int.mul"(%_eta0, %7) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
              "eco.yield"(%8) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        "eco.return"(%9) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["i64"], function_type = (!eco.value, i64) -> (i64), sym_name = "Lss_pick_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%f: !eco.value, %n: i64, %acc: i64):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %5, %6, %7, %8, %9 = "scf.while"(%f, %n, %acc, %3, %4) ({
            ^bb0(%10: !eco.value, %11: i64, %12: i64, %13: i1, %14: i64):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, i64, i64, i1, i64]} : (i1, !eco.value, i64, i64, i1, i64) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: i64, %19: i64, %20: i1, %21: i64):
              %22 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %23 = "eco.int.le"(%18, %22) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
              %30, %31, %32, %33, %34 = "eco.case"(%23) ({
                    %24 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %24, %19) {_operand_types = [!eco.value, i64, i64, i1, i64]} : (!eco.value, i64, i64, i1, i64) -> () 
              }, {
                    %25 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %26 = "eco.int.sub"(%18, %25) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %27 = "eco.papExtend"(%17, %19) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Lss_pick_$_1, _operand_types = [!eco.value, i64], _pap_prefix = 1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
                    %28 = "arith.constant"() {value = false} : () -> i1 
                    %29 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%17, %26, %27, %28, %29) {_operand_types = [!eco.value, i64, i64, i1, i64]} : (!eco.value, i64, i64, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, i64, i64, i1, i64) 
              "scf.yield"(%30, %31, %32, %33, %34) {_operand_types = [!eco.value, i64, i64, i1, i64]} : (!eco.value, i64, i64, i1, i64) -> () 
        }) {_operand_types = [!eco.value, i64, i64, i1, i64]} : (!eco.value, i64, i64, i1, i64) -> (!eco.value, i64, i64, i1, i64) 
        "eco.return"(%9) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value", "i64", "i64"], eco.logical_result_types = ["i64"], function_type = (!eco.value, i64, i64) -> (i64), sym_name = "Lss_repeatApply_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%n: i64):
        %1 = "eco.int.negate"(%n) {_operand_types = [i64]} : (i64) -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Basics_negate_$_7", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_7: i64, %mono_inline_8: !eco.value):
        %29 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_5_20, num_captured = 0} : () -> !eco.value 
        %30 = "arith.constant"() {value = false} : () -> i1 
        %31 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %32, %33, %34, %35 = "scf.while"(%mono_inline_7, %mono_inline_8, %30, %31) ({
            ^bb0(%36: i64, %37: !eco.value, %38: i1, %39: i64):
              %41 = "arith.constant"() {value = true} : () -> i1 
              %40 = "arith.xori"(%38, %41) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%40, %36, %37, %38, %39) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%42: i64, %43: !eco.value, %44: i1, %45: i64):
              %46 = "eco.get_tag"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %47 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %48 = "arith.cmpi"(%46, %47) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %57, %58, %59, %60 = "eco.case"(%48) ({
                    %49 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%42, %43, %49, %42) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %50 = "eco.project.list_head"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %51 = "eco.project.list_tail"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %54 = "eco.papExtend"(%50, %42) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, i64], _result_kind = 1 : i8, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
                    %55 = "arith.constant"() {value = false} : () -> i1 
                    %56 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%54, %51, %55, %56) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%57, %58, %59, %60) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%35) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "_tail_mono_inline_5_20", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64):
        %61 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %62 = "eco.int.add"(%x, %61) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%62) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Lss_lambda_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64):
        %63 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %64 = "eco.int.mul"(%x, %63) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%64) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Lss_lambda_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_4: i64, %mono_inline_2: i64, %mono_inline_3: i64):
        %65 = "eco.papCreate"(%mono_inline_4) {_fast_evaluator = @_tail_mono_inline_0_9$cap, _operand_types = [i64], _result_kind = 1 : i8, arity = 3, function = @_tail_mono_inline_0_9$clo, num_captured = 1, slot_kinds = array<i8: 1>} : (i64) -> !eco.value 
        %66 = "arith.constant"() {value = false} : () -> i1 
        %67 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %68, %69, %70, %71 = "scf.while"(%mono_inline_2, %mono_inline_3, %66, %67) ({
            ^bb0(%72: i64, %73: i64, %74: i1, %75: i64):
              %77 = "arith.constant"() {value = true} : () -> i1 
              %76 = "arith.xori"(%74, %77) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%76, %72, %73, %74, %75) {_operand_types = [i1, i64, i64, i1, i64]} : (i1, i64, i64, i1, i64) -> () 
        }, {
            ^bb0(%78: i64, %79: i64, %80: i1, %81: i64):
              %82 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %83 = "eco.int.le"(%78, %82) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
              %91, %92, %93, %94 = "eco.case"(%83) ({
                    %84 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%78, %79, %84, %79) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }, {
                    %85 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %86 = "eco.int.sub"(%78, %85) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %88 = "eco.int.add"(%79, %mono_inline_4) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %89 = "arith.constant"() {value = false} : () -> i1 
                    %90 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%86, %88, %89, %90) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, i64, i1, i64) 
              "scf.yield"(%91, %92, %93, %94) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
        }) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> (i64, i64, i1, i64) 
        "eco.return"(%71) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64, i64) -> (i64), sym_name = "_tail_mono_inline_0_9$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %mono_inline_2: i64, %mono_inline_3: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = true} : (!eco.value) -> i64 
        %4 = "eco.call"(%3, %mono_inline_2, %mono_inline_3) <{_operand_types = [i64, i64, i64], callee = @_tail_mono_inline_0_9$cap}> : (i64, i64, i64) -> i64 
        "eco.return"(%4) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value", "i64", "i64"], eco.logical_result_types = ["i64"], function_type = (!eco.value, i64, i64) -> (i64), sym_name = "_tail_mono_inline_0_9$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Lss_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [], func_args = [0], strings = [], types = [[0, 0, 0], [1, 5, 0, 1, 0], [2, 1, 1]]} : () -> () 
} 
