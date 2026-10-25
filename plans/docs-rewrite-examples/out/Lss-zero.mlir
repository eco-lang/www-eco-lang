module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %6 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @Lss_pick_$_1, num_captured = 0} : () -> !eco.value 
        %7 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %8 = "eco.int.gt"(%0, %7) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
        %9 = "eco.box"(%8) {_operand_types = [i1]} : (i1) -> !eco.value 
        %10 = "eco.papExtend"(%6, %9) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %11 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %12 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %1 = "eco.call"(%10, %11, %12) <{_operand_types = [!eco.value, i64, i64], callee = @Lss_repeatApply_$_2}> : (!eco.value, i64, i64) -> i64 
        %15 = "eco.papCreate"(%0) {_fast_evaluator = @_tail_mono_inline_0_9$cap, _operand_types = [i64], _result_kind = 1 : i8, arity = 3, function = @_tail_mono_inline_0_9$clo, num_captured = 1, slot_kinds = array<i8: 1>} : (i64) -> !eco.value 
        %17 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %18 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %2 = "eco.papExtend"(%15, %17, %18) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, i64], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 1>} : (!eco.value, i64, i64) -> i64 
        %20 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %21 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Basics_negate_$_6, num_captured = 0} : () -> !eco.value 
        %22 = "eco.construct.list"(%21, %20) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %23 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Lss_lambda_3, num_captured = 0} : () -> !eco.value 
        %24 = "eco.construct.list"(%23, %22) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %25 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Lss_lambda_2, num_captured = 0} : () -> !eco.value 
        %3 = "eco.construct.list"(%25, %24) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %27 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_5_20, num_captured = 0} : () -> !eco.value 
        %29 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %4 = "eco.papExtend"(%27, %29, %3) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, !eco.value], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> i64 
        %31 = "eco.int.add"(%2, %1) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %32 = "eco.int.add"(%31, %4) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %33 = "eco.string.from_int"(%32) {_operand_types = [i64]} : (i64) -> !eco.value 
        %34 = "eco.call"(%33) <{_operand_types = [!eco.value], callee = @Html_text_$_5}> : (!eco.value) -> !eco.value 
        "eco.return"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
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
      ^bb0(%_eta115: !eco.value):
        %1 = "eco.call"(%_eta115) <{_operand_types = [!eco.value], callee = @VirtualDom_text_$_8}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Html_text_$_5", sym_visibility = "private"} : () -> () 
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
      ^bb0(%arg0: !eco.value):
        %1 = "eco.call"(%arg0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "VirtualDom_text_$_8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_7: i64, %mono_inline_8: !eco.value):
        %28 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_5_20, num_captured = 0} : () -> !eco.value 
        %29 = "arith.constant"() {value = false} : () -> i1 
        %30 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %31, %32, %33, %34 = "scf.while"(%mono_inline_7, %mono_inline_8, %29, %30) ({
            ^bb0(%35: i64, %36: !eco.value, %37: i1, %38: i64):
              %40 = "arith.constant"() {value = true} : () -> i1 
              %39 = "arith.xori"(%37, %40) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%39, %35, %36, %37, %38) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%41: i64, %42: !eco.value, %43: i1, %44: i64):
              %45 = "eco.get_tag"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %46 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %47 = "arith.cmpi"(%45, %46) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %56, %57, %58, %59 = "eco.case"(%47) ({
                    %48 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%41, %42, %48, %41) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %49 = "eco.project.list_head"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %50 = "eco.project.list_tail"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %53 = "eco.papExtend"(%49, %41) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, i64], _result_kind = 1 : i8, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
                    %54 = "arith.constant"() {value = false} : () -> i1 
                    %55 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%53, %50, %54, %55) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%56, %57, %58, %59) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%34) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "_tail_mono_inline_5_20", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64):
        %60 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %61 = "eco.int.add"(%x, %60) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%61) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Lss_lambda_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64):
        %62 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %63 = "eco.int.mul"(%x, %62) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%63) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Lss_lambda_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_4: i64, %mono_inline_2: i64, %mono_inline_3: i64):
        %64 = "eco.papCreate"(%mono_inline_4) {_fast_evaluator = @_tail_mono_inline_0_9$cap, _operand_types = [i64], _result_kind = 1 : i8, arity = 3, function = @_tail_mono_inline_0_9$clo, num_captured = 1, slot_kinds = array<i8: 1>} : (i64) -> !eco.value 
        %65 = "arith.constant"() {value = false} : () -> i1 
        %66 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %67, %68, %69, %70 = "scf.while"(%mono_inline_2, %mono_inline_3, %65, %66) ({
            ^bb0(%71: i64, %72: i64, %73: i1, %74: i64):
              %76 = "arith.constant"() {value = true} : () -> i1 
              %75 = "arith.xori"(%73, %76) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%75, %71, %72, %73, %74) {_operand_types = [i1, i64, i64, i1, i64]} : (i1, i64, i64, i1, i64) -> () 
        }, {
            ^bb0(%77: i64, %78: i64, %79: i1, %80: i64):
              %81 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %82 = "eco.int.le"(%77, %81) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
              %90, %91, %92, %93 = "eco.case"(%82) ({
                    %83 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%77, %78, %83, %78) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }, {
                    %84 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %85 = "eco.int.sub"(%77, %84) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %87 = "eco.int.add"(%78, %mono_inline_4) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %88 = "arith.constant"() {value = false} : () -> i1 
                    %89 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%85, %87, %88, %89) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, i64, i1, i64) 
              "scf.yield"(%90, %91, %92, %93) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
        }) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> (i64, i64, i1, i64) 
        "eco.return"(%70) {_operand_types = [i64]} : (i64) -> () 
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
