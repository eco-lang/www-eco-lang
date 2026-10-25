module {
  "func.func"() ({
        %10 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 3, function = @Stage_scale_$_1, num_captured = 0} : () -> !eco.value 
        %11 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %12 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %5 = "eco.papExtend"(%10, %11, %12) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, i64], remaining_arity = 3, slot_kinds = array<i8: 1, 1>} : (!eco.value, i64, i64) -> !eco.value 
        %14 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %15 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %16 = "eco.construct.list"(%15, %14) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %17 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %6 = "eco.construct.list"(%17, %16) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %7 = "eco.papCreate"(%5) {_fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value], arity = 3, function = @Stage_lambda_12$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
        %8 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %21 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %0 = "eco.call"(%7, %8, %21, %6) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_12}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
        %23 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 1, function = @Stage_inc_$_3, num_captured = 0} : () -> !eco.value 
        %24 = "arith.constant"() {value = 10 : i64} : () -> i64 
        %1 = "eco.call"(%23, %24) <{_operand_types = [!eco.value, i64], callee = @Stage_twice_$_4}> : (!eco.value, i64) -> i64 
        %26 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %27 = "arith.constant"() {value = 4 : i64} : () -> i64 
        %28 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %29 = "eco.int.mul"(%26, %26) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %34 = "eco.int.mul"(%29, %27) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %2 = "eco.int.add"(%34, %28) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %36 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %37 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %3 = "eco.int.add"(%36, %37) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %42 = "eco.int.add"(%3, %2) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %43 = "eco.int.add"(%42, %1) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %45 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @Basics_add_$_9, num_captured = 0} : () -> !eco.value 
        %46 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %47 = "eco.call"(%45, %46, %0) <{_operand_types = [!eco.value, i64, !eco.value], callee = @List_foldl_$_10}> : (!eco.value, i64, !eco.value) -> i64 
        %48 = "eco.int.add"(%43, %47) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %4 = "eco.string.from_int"(%48) {_operand_types = [i64]} : (i64) -> !eco.value 
        %50 = "eco.call"(%4) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%50) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Stage_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%k: i64, %x: i64, %y: i64):
        %3 = "eco.int.mul"(%k, %k) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %5 = "eco.int.mul"(%3, %x) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %6 = "eco.int.add"(%5, %y) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%6) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64, i64) -> (i64), sym_name = "Stage_scale_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_eta3: i64):
        %1 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %5 = "eco.int.add"(%1, %_eta3) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%5) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["i64"], function_type = (i64) -> (i64), sym_name = "Stage_inc_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%f: !eco.value, %x: i64):
        %7 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %2 = "eco.int.add"(%7, %x) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %3 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %13 = "eco.int.add"(%3, %2) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%13) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["i64"], function_type = (!eco.value, i64) -> (i64), sym_name = "Stage_twice_$_4", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: i64):
        %2 = "eco.int.add"(%arg0, %arg1) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        "eco.return"(%2) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "i64"], eco.logical_result_types = ["i64"], function_type = (i64, i64) -> (i64), sym_name = "Basics_add_$_9", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%func: !eco.value, %acc: i64, %list: !eco.value):
        %3 = "arith.constant"() {value = false} : () -> i1 
        %4 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %5, %6, %7, %8, %9 = "scf.while"(%func, %acc, %list, %3, %4) ({
            ^bb0(%10: !eco.value, %11: i64, %12: !eco.value, %13: i1, %14: i64):
              %16 = "arith.constant"() {value = true} : () -> i1 
              %15 = "arith.xori"(%13, %16) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%15, %10, %11, %12, %13, %14) {_operand_types = [i1, !eco.value, i64, !eco.value, i1, i64]} : (i1, !eco.value, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%17: !eco.value, %18: i64, %19: !eco.value, %20: i1, %21: i64):
              %22 = "eco.get_tag"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %31, %32, %33, %34, %35 = "eco.case"(%24) ({
                    %25 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%17, %18, %19, %25, %18) {_operand_types = [!eco.value, i64, !eco.value, i1, i64]} : (!eco.value, i64, !eco.value, i1, i64) -> () 
              }, {
                    %26 = "eco.project.list_head"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %27 = "eco.project.list_tail"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %28 = "eco.int.add"(%26, %18) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, i64, !eco.value, i1, i64]} : (!eco.value, i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, i64, !eco.value, i1, i64) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, i64, !eco.value, i1, i64]} : (!eco.value, i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [!eco.value, i64, !eco.value, i1, i64]} : (!eco.value, i64, !eco.value, i1, i64) -> (!eco.value, i64, !eco.value, i1, i64) 
        "eco.return"(%9) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["i64"], function_type = (!eco.value, i64, !eco.value) -> (i64), sym_name = "List_foldl_$_10", sym_visibility = "private"} : () -> () 
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
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_13}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_14}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_12}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_12", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%list: !eco.value):
        %1 = "eco.call"(%list) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_reverse, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "List_reverse_$_13", sym_visibility = "private"} : () -> () 
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
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage_lambda_12$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_14", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.list"(%arg0, %arg1) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "List_cons_$_15", sym_visibility = "private"} : () -> () 
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
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_16", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_0: !eco.value, %x: i64, %acc: !eco.value):
        %36 = "eco.papExtend"(%mono_inline_0, %x) {_call_kind = "singleton_fast", _capture_abi = [i64, i64], _fast_evaluator = @Stage_scale_$_1, _operand_types = [!eco.value, i64], _pap_prefix = 2, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> i64 
        %37 = "eco.construct.list"(%36, %acc) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Stage_lambda_12$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64, %acc: !eco.value):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %x, %acc) <{_operand_types = [!eco.value, i64, !eco.value], callee = @Stage_lambda_12$cap}> : (!eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Stage_lambda_12$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Stage_main_$_0}> : () -> !eco.value 
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
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [], fields = [], func_args = [], strings = [], types = [[0, 0, 0], [1, 1, 0]]} : () -> () 
} 
