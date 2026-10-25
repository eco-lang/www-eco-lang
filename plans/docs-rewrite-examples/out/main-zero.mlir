module {
  "func.func"() ({
        %0 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %3 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @Main_add_$_1, num_captured = 0} : () -> !eco.value 
        %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %1 = "eco.papExtend"(%3, %4) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64], remaining_arity = 2, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value 
        %2 = "arith.constant"() {value = 10 : i64} : () -> i64 
        %7 = "eco.papExtend"(%1, %2) {_call_kind = "singleton_fast", _capture_abi = [i64], _fast_evaluator = @Main_add_$_1, _operand_types = [!eco.value, i64], _pap_prefix = 1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
        %8 = "eco.papExtend"(%1, %7) {_call_kind = "singleton_fast", _capture_abi = [i64], _fast_evaluator = @Main_add_$_1, _operand_types = [!eco.value, i64], _pap_prefix = 1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
        %9 = "eco.call"(%0, %8) <{_operand_types = [i64, i64], callee = @Main_sumTo_$_3}> : (i64, i64) -> i64 
        %10 = "eco.string.from_int"(%9) {_operand_types = [i64]} : (i64) -> !eco.value 
        %11 = "arith.constant"() {value = 2.0 : f64} : () -> f64 
        %12 = "arith.constant"() {value = 3.0 : f64} : () -> f64 
        %13 = "eco.construct.custom"(%11, %12) {_operand_types = [f64, f64], constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value 
        %14 = "eco.call"(%13) <{_operand_types = [!eco.value], callee = @Main_area_$_5}> : (!eco.value) -> f64 
        %15 = "eco.string.from_float"(%14) {_operand_types = [f64]} : (f64) -> !eco.value 
        %16 = "eco.string_literal"() {value = ","} : () -> !eco.value 
        %17 = "eco.papCreate"() {arity = 1, function = @String_fromInt_$_6, num_captured = 0} : () -> !eco.value 
        %20 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Main_lambda_0, num_captured = 0} : () -> !eco.value 
        %23 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %24 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %25 = "eco.construct.list"(%24, %23) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %26 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %27 = "eco.construct.list"(%26, %25) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %28 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %21 = "eco.construct.list"(%28, %27) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %30 = "eco.papCreate"(%20) {_fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value], arity = 3, function = @Main_lambda_18$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
        %31 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %18 = "eco.call"(%30, %31, %21) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldr_$_19}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        %33 = "eco.papCreate"(%17) {_fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value], arity = 3, function = @Main_lambda_17$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
        %34 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %35 = "eco.call"(%33, %34, %18) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldr_$_13}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        %36 = "eco.call"(%16, %35) <{_operand_types = [!eco.value, !eco.value], callee = @String_join_$_9}> : (!eco.value, !eco.value) -> !eco.value 
        %37 = "eco.call"(%15, %36) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_10}> : (!eco.value, !eco.value) -> !eco.value 
        %38 = "eco.call"(%10, %37) <{_operand_types = [!eco.value, !eco.value], callee = @Basics_append_$_10}> : (!eco.value, !eco.value) -> !eco.value 
        %39 = "eco.call"(%38) <{_operand_types = [!eco.value], callee = @Html_text_$_11}> : (!eco.value) -> !eco.value 
        "eco.return"(%39) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Main_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%a: i64, %b: i64):
        %2 = "eco.int.add"(%a, %b) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%2) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64) -> (i64), sym_name = "Main_add_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%acc: i64, %n: i64):
        %2 = "arith.constant"() {value = false} : () -> i1 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4, %5, %6, %7 = "scf.while"(%acc, %n, %2, %3) ({
            ^bb0(%8: i64, %9: i64, %10: i1, %11: i64):
              %13 = "arith.constant"() {value = true} : () -> i1 
              %12 = "arith.xori"(%10, %13) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%12, %8, %9, %10, %11) {_operand_types = [i1, i64, i64, i1, i64]} : (i1, i64, i64, i1, i64) -> () 
        }, {
            ^bb0(%14: i64, %15: i64, %16: i1, %17: i64):
              %18 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %19 = "eco.int.le"(%15, %18) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
              %26, %27, %28, %29 = "eco.case"(%19) ({
                    %20 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%14, %15, %20, %14) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }, {
                    %21 = "eco.int.add"(%14, %15) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %22 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %23 = "eco.int.sub"(%15, %22) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %24 = "arith.constant"() {value = false} : () -> i1 
                    %25 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%21, %23, %24, %25) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, i64, i1, i64) 
              "scf.yield"(%26, %27, %28, %29) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> () 
        }) {_operand_types = [i64, i64, i1, i64]} : (i64, i64, i1, i64) -> (i64, i64, i1, i64) 
        "eco.return"(%7) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64) -> (i64), sym_name = "Main_sumTo_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: f64, %arg1: f64):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [f64, f64], constructor = "Rect", size = 2, slot_kinds = array<i8: 2, 2>, tag = 1} : (f64, f64) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (f64, f64) -> (!eco.value), sym_name = "Main_Rect_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%shape: !eco.value):
        %14 = "eco.case"(%shape) ({
              %2 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %3 = "arith.constant"() {value = 3.14 : f64} : () -> f64 
              %4 = "eco.float.mul"(%3, %2) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              %5 = "eco.float.mul"(%4, %2) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              "eco.yield"(%5) {_operand_types = [f64]} : (f64) -> () 
        }, {
              %7 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %9 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> f64 
              %10 = "eco.float.mul"(%7, %9) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              "eco.yield"(%10) {_operand_types = [f64]} : (f64) -> () 
        }, {
              %12 = "eco.project.custom"(%shape) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> f64 
              %13 = "eco.float.mul"(%12, %12) {_operand_types = [f64, f64]} : (f64, f64) -> f64 
              "eco.yield"(%13) {_operand_types = [f64]} : (f64) -> () 
        }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2>} : (!eco.value) -> f64 
        "eco.return"(%14) {_operand_types = [f64]} : (f64) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["f64"], function_type = (!eco.value) -> (f64), sym_name = "Main_area_$_5", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.string.from_int"(%arg0) {_operand_types = [i64]} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "String_fromInt_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%sep: !eco.value, %chunks: !eco.value):
        %2 = "eco.call"(%chunks) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_toArray}> : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%sep, %2) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_String_join}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "String_join_$_9", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.call"(%arg0, %arg1) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Utils_append, eco.cse_safe}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Basics_append_$_10", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_eta114: !eco.value):
        %1 = "eco.call"(%_eta114) <{_operand_types = [!eco.value], callee = @VirtualDom_text_$_12}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Html_text_$_11", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.call"(%arg0) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "VirtualDom_text_$_12", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%fn: !eco.value, %acc: !eco.value, %ls: !eco.value):
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4 = "eco.call"(%fn, %acc, %3, %ls) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_14}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "cons:i:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldr_$_13", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%fn: !eco.value, %acc: !eco.value, %ctr: i64, %ls: !eco.value):
        %4 = "eco.get_tag"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %5 = "arith.constant"() {value = 65533 : i32} : () -> i32 
        %6 = "arith.cmpi"(%4, %5) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %46 = "eco.case"(%6) ({
              "eco.yield"(%acc) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %7 = "eco.project.list_head"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
              %8 = "eco.project.list_tail"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %9 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %10 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %11 = "arith.cmpi"(%9, %10) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %45 = "eco.case"(%11) ({
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_15}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_16}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_14}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "i64", "cons:i:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_14", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%list: !eco.value):
        %1 = "eco.call"(%list) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_reverse, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "List_reverse_$_15", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: !eco.value, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: !eco.value, %12: !eco.value, %13: i1, %14: !eco.value):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: !eco.value, %19: !eco.value, %20: i1, %21: !eco.value):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_17$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "cons:i:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_16", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.list"(%arg0, %arg1) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "List_cons_$_17", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: !eco.value, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: !eco.value, %12: !eco.value, %13: i1, %14: !eco.value):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: !eco.value, %19: !eco.value, %20: i1, %21: !eco.value):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.construct.list"(%26, %18) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_18", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%fn: !eco.value, %acc: !eco.value, %ls: !eco.value):
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4 = "eco.call"(%fn, %acc, %3, %ls) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_20}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldr_$_19", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%fn: !eco.value, %acc: !eco.value, %ctr: i64, %ls: !eco.value):
        %4 = "eco.get_tag"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %5 = "arith.constant"() {value = 65533 : i32} : () -> i32 
        %6 = "arith.cmpi"(%4, %5) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %46 = "eco.case"(%6) ({
              "eco.yield"(%acc) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %7 = "eco.project.list_head"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
              %8 = "eco.project.list_tail"(%ls) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
              %9 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %10 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %11 = "arith.cmpi"(%9, %10) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %45 = "eco.case"(%11) ({
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_15}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_21}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_20}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_20", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: !eco.value, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: !eco.value, %12: !eco.value, %13: i1, %14: !eco.value):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: !eco.value, %19: !eco.value, %20: i1, %21: !eco.value):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Main_lambda_18$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_21", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_2: !eco.value, %x: i64, %acc: !eco.value):
        %36 = "eco.papExtend"(%mono_inline_2, %x) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64], remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value 
        %37 = "eco.construct.list"(%36, %acc) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Main_lambda_17$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64, %acc: !eco.value):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %x, %acc) <{_operand_types = [!eco.value, i64, !eco.value], callee = @Main_lambda_17$cap}> : (!eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Main_lambda_17$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_4: !eco.value, %x: i64, %acc: !eco.value):
        %22 = "eco.papExtend"(%mono_inline_4, %x) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @Main_lambda_0, _operand_types = [!eco.value, i64], remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
        %23 = "eco.construct.list"(%22, %acc) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%23) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Main_lambda_18$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64, %acc: !eco.value):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %x, %acc) <{_operand_types = [!eco.value, i64, !eco.value], callee = @Main_lambda_18$cap}> : (!eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Main_lambda_18$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%x: i64):
        %22 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %23 = "eco.int.mul"(%x, %22) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%23) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Main_lambda_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Main_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_List_reverse", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_List_toArray", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_String_join", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Utils_append", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 0, 0, 1], [1, 2, 1, 2], [2, 4, 3, 1]], fields = [[1, 4], [1, 4], [3, 4], [1, 4]], func_args = [], strings = ["Circle", "field0", "Rect", "field1", "Square"], types = [[0, 0, 0], [1, 1, 0], [2, 0, 4], [3, 1, 2], [4, 0, 1], [5, 4, 0, 3]]} : () -> () 
} 
