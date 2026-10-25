module {
  "func.func"() ({
        %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %5 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %6 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %10 = "eco.int.add"(%4, %5) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %11 = "eco.int.add"(%10, %6) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %12 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %13 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %14 = "eco.construct.list"(%13, %12) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %15 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %16 = "eco.call"(%14, %15) <{_operand_types = [!eco.value, i64], callee = @Stage2_makeLookup_$_1}> : (!eco.value, i64) -> !eco.value 
        %17 = "eco.unbox"(%16) {_operand_types = [!eco.value]} : (!eco.value) -> i1 
        %20 = "eco.case"(%17) ({
              %18 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%18) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %19 = "arith.constant"() {value = 0 : i64} : () -> i64 
              "eco.yield"(%19) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> i64 
        %0 = "eco.int.add"(%11, %20) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %22 = "eco.papCreate"() {arity = 2, function = @Stage2_makeLookup_$_1, num_captured = 0} : () -> !eco.value 
        %23 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %24 = "arith.constant"() {value = 9 : i64} : () -> i64 
        %25 = "eco.construct.list"(%24, %23) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %26 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %27 = "eco.construct.list"(%26, %25) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %28 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %29 = "eco.construct.list"(%28, %27) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %1 = "eco.papExtend"(%22, %29) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
        %31 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %32 = "arith.constant"() {value = 5 : i64} : () -> i64 
        %33 = "eco.construct.list"(%32, %31) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %34 = "arith.constant"() {value = 4 : i64} : () -> i64 
        %35 = "eco.construct.list"(%34, %33) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %36 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %37 = "eco.construct.list"(%36, %35) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %38 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %39 = "eco.construct.list"(%38, %37) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %40 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %41 = "eco.construct.list"(%40, %39) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %2 = "eco.call"(%1, %41) <{_operand_types = [!eco.value, !eco.value], callee = @List_filter_$_2}> : (!eco.value, !eco.value) -> !eco.value 
        %43 = "eco.call"(%2) <{_operand_types = [!eco.value], callee = @List_length_$_3}> : (!eco.value) -> i64 
        %44 = "eco.int.add"(%43, %0) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %3 = "eco.string.from_int"(%44) {_operand_types = [i64]} : (i64) -> !eco.value 
        %46 = "eco.call"(%3) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "Stage2_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value, %x: i64):
        %6 = "eco.papCreate"() {arity = 2, function = @Set_insert_$_20, num_captured = 0} : () -> !eco.value 
        %7 = "eco.call"() <{callee = @Set_empty_$_21}> : () -> !eco.value 
        %2 = "eco.call"(%6, %7, %xs) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_22}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        %9 = "eco.project.custom"(%2) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %10 = "eco.call"(%x, %9) <{_operand_types = [i64, !eco.value], callee = @Dict_member_$_16}> : (i64, !eco.value) -> !eco.value 
        "eco.return"(%10) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), sym_name = "Stage2_makeLookup_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%isGood: !eco.value, %list: !eco.value):
        %2 = "eco.papCreate"(%isGood) {_fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value], arity = 3, function = @Stage2_lambda_5$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %7 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %8 = "eco.call"(%2, %3, %7, %list) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_9}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "List_filter_$_2", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%xs: !eco.value):
        %1 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_11_54, num_captured = 0} : () -> !eco.value 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4 = "eco.papExtend"(%1, %3, %xs) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64, !eco.value], _result_kind = 1 : i8, remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> i64 
        "eco.return"(%4) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "List_length_$_3", sym_visibility = "private"} : () -> () 
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
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_10}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_11}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_9}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_9", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%list: !eco.value):
        %1 = "eco.call"(%list) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_reverse, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "List_reverse_$_10", sym_visibility = "private"} : () -> () 
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
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_lambda_5$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_11", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.list"(%arg0, %arg1) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "List_cons_$_12", sym_visibility = "private"} : () -> () 
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
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_13", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%key: i64, %dict: !eco.value):
        %2 = "eco.call"(%key, %dict) <{_operand_types = [i64, !eco.value], callee = @Dict_get_$_17}> : (i64, !eco.value) -> !eco.value 
        %4 = "eco.get_tag"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %5 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %6 = "arith.cmpi"(%4, %5) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %11 = "eco.case"(%6) ({
              %7 = "arith.constant"() {value = true} : () -> i1 
              %8 = "eco.box"(%7) {_operand_types = [i1]} : (i1) -> !eco.value 
              "eco.yield"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %9 = "arith.constant"() {value = false} : () -> i1 
              %10 = "eco.box"(%9) {_operand_types = [i1]} : (i1) -> !eco.value 
              "eco.yield"(%10) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%11) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "value"], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Dict_member_$_16", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%targetKey: i64, %dict: !eco.value):
        %2 = "arith.constant"() {value = false} : () -> i1 
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %4, %5, %6, %7 = "scf.while"(%targetKey, %dict, %2, %3) ({
            ^bb0(%8: i64, %9: !eco.value, %10: i1, %11: !eco.value):
              %13 = "arith.constant"() {value = true} : () -> i1 
              %12 = "arith.xori"(%10, %13) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%12, %8, %9, %10, %11) {_operand_types = [i1, i64, !eco.value, i1, !eco.value]} : (i1, i64, !eco.value, i1, !eco.value) -> () 
        }, {
            ^bb0(%14: i64, %15: !eco.value, %16: i1, %17: !eco.value):
              %18 = "eco.get_tag"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %19 = "arith.constant"() {value = 1 : i32} : () -> i32 
              %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %41, %42, %43, %44 = "eco.case"(%20) ({
                    %21 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    %22 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%14, %15, %22, %21) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
              }, {
                    %24 = "eco.project.custom"(%15) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                    %25 = "eco.project.custom"(%15) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                    %26 = "eco.project.custom"(%15) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                    %27 = "eco.project.custom"(%15) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                    %28 = "eco.int.cmp_order"(%14, %24) {_operand_types = [i64, i64]} : (i64, i64) -> !eco.value 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    %37, %38, %39, %40 = "eco.case"(%28) ({
                          %31 = "arith.constant"() {value = false} : () -> i1 
                          %32 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                          "eco.yield"(%14, %26, %31, %32) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
                    }, {
                          %33 = "eco.construct.custom"(%25) {_operand_types = [!eco.value], constructor = "Just", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
                          %34 = "arith.constant"() {value = true} : () -> i1 
                          "eco.yield"(%14, %15, %34, %33) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
                    }, {
                          %35 = "arith.constant"() {value = false} : () -> i1 
                          %36 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                          "eco.yield"(%14, %27, %35, %36) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
                    }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2>} : (!eco.value) -> (i64, !eco.value, i1, !eco.value) 
                    "eco.yield"(%37, %38, %39, %40) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, !eco.value) 
              "scf.yield"(%41, %42, %43, %44) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [i64, !eco.value, i1, !eco.value]} : (i64, !eco.value, i1, !eco.value) -> (i64, !eco.value, i1, !eco.value) 
        "eco.return"(%7) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "value"], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Dict_get_$_17", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %45 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Maybe_Nothing_$_18", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Just", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Maybe_Just_$_19", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%key: i64, %_v0: !eco.value):
        %2 = "eco.project.custom"(%_v0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %4 = "eco.call"(%key, %3, %2) <{_operand_types = [i64, !eco.value, !eco.value], callee = @Dict_insert_$_25}> : (i64, !eco.value, !eco.value) -> !eco.value 
        %5 = "eco.construct.custom"(%4) {_operand_types = [!eco.value], constructor = "Set_elm_builtin", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%5) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "custom:0:1:v"], eco.logical_result_types = ["custom:0:1:v"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Set_insert_$_20", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Set_empty_$_21"} : () -> () 
  "func.func"() ({
        %0 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        %1 = "eco.construct.custom"(%0) {_operand_types = [!eco.value], constructor = "Set_elm_builtin", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Set_empty_$_21", sym_visibility = "private"} : () -> () 
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
                    %28 = "eco.call"(%26, %18) <{_operand_types = [i64, !eco.value], callee = @Set_insert_$_20}> : (i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "custom:0:1:v", "cons:i:v"], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_22", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %36 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        "eco.return"(%36) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Dict_RBEmpty_elm_builtin_$_23", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Set_elm_builtin", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Set_Set_elm_builtin_$_24", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%key: i64, %value: !eco.value, %dict: !eco.value):
        %3 = "eco.call"(%key, %value, %dict) <{_operand_types = [i64, !eco.value, !eco.value], callee = @Dict_insertHelp_$_26}> : (i64, !eco.value, !eco.value) -> !eco.value 
        %5 = "eco.get_tag"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %6 = "arith.constant"() {value = 65535 : i32} : () -> i32 
        %7 = "arith.cmpi"(%5, %6) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %21 = "eco.case"(%7) ({
              %8 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %9 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %10 = "arith.constant"() {value = 0 : i32} : () -> i32 
              %11 = "arith.cmpi"(%9, %10) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %20 = "eco.case"(%11) ({
                    %12 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                    %14 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                    %15 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                    %16 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                    %17 = "eco.project.custom"(%3) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                    %18 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                    %19 = "eco.construct.custom"(%18, %14, %15, %16, %17) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    "eco.yield"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%20) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              "eco.yield"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "value", "value"], eco.logical_result_types = ["value"], function_type = (i64, !eco.value, !eco.value) -> (!eco.value), sym_name = "Dict_insert_$_25", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%key: i64, %value: !eco.value, %dict: !eco.value):
        %3 = "eco.get_tag"(%dict) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %4 = "arith.constant"() {value = 1 : i32} : () -> i32 
        %5 = "arith.cmpi"(%3, %4) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %24 = "eco.case"(%5) ({
              %6 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
              %7 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
              %8 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
              %9 = "eco.construct.custom"(%6, %key, %value, %7, %8) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
              "eco.yield"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %10 = "eco.project.custom"(%dict) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %12 = "eco.project.custom"(%dict) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
              %13 = "eco.project.custom"(%dict) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
              %14 = "eco.project.custom"(%dict) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
              %15 = "eco.project.custom"(%dict) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
              %16 = "eco.int.cmp_order"(%key, %12) {_operand_types = [i64, i64]} : (i64, i64) -> !eco.value 
              %23 = "eco.case"(%16) ({
                    %18 = "eco.call"(%key, %value, %14) <{_operand_types = [i64, !eco.value, !eco.value], callee = @Dict_insertHelp_$_26}> : (i64, !eco.value, !eco.value) -> !eco.value 
                    %19 = "eco.call"(%10, %12, %13, %18, %15) <{_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], callee = @Dict_balance_$_30}> : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %20 = "eco.construct.custom"(%10, %12, %value, %14, %15) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%20) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %21 = "eco.call"(%key, %value, %15) <{_operand_types = [i64, !eco.value, !eco.value], callee = @Dict_insertHelp_$_26}> : (i64, !eco.value, !eco.value) -> !eco.value 
                    %22 = "eco.call"(%10, %12, %13, %14, %21) <{_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], callee = @Dict_balance_$_30}> : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%22) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2>} : (!eco.value) -> !eco.value 
              "eco.yield"(%23) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%24) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "value", "value"], eco.logical_result_types = ["value"], function_type = (i64, !eco.value, !eco.value) -> (!eco.value), sym_name = "Dict_insertHelp_$_26", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %25 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
        "eco.return"(%25) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Dict_Black_$_27", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64, %arg2: !eco.value, %arg3: !eco.value, %arg4: !eco.value):
        %5 = "eco.construct.custom"(%arg0, %arg1, %arg2, %arg3, %arg4) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
        "eco.return"(%5) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "Dict_RBNode_elm_builtin_$_28", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %6 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
        "eco.return"(%6) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = () -> (!eco.value), sym_name = "Dict_Red_$_29", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%color: !eco.value, %key: i64, %value: !eco.value, %left: !eco.value, %right: !eco.value):
        %5 = "eco.get_tag"(%right) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %6 = "arith.constant"() {value = 65535 : i32} : () -> i32 
        %7 = "arith.cmpi"(%5, %6) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %130 = "eco.case"(%7) ({
              %8 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %9 = "eco.get_tag"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %10 = "arith.constant"() {value = 0 : i32} : () -> i32 
              %11 = "arith.cmpi"(%9, %10) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %87 = "eco.case"(%11) ({
                    %12 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                    %14 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                    %15 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                    %16 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                    %17 = "eco.project.custom"(%right) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                    %18 = "eco.get_tag"(%left) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %19 = "arith.constant"() {value = 65535 : i32} : () -> i32 
                    %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%20) ({
                          %21 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 0 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %40 = "eco.case"(%24) ({
                                %25 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                %27 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                                %28 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                                %29 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                %30 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                                %31 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
                                %32 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                %33 = "eco.construct.custom"(%32, %27, %28, %29, %30) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                %34 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                %35 = "eco.construct.custom"(%34, %14, %15, %16, %17) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                %36 = "eco.construct.custom"(%31, %key, %value, %33, %35) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%36) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %37 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
                                %38 = "eco.construct.custom"(%37, %key, %value, %left, %16) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                %39 = "eco.construct.custom"(%color, %14, %15, %38, %17) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%39) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%40) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %41 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
                          %42 = "eco.construct.custom"(%41, %key, %value, %left, %16) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                          %43 = "eco.construct.custom"(%color, %14, %15, %42, %17) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %45 = "eco.get_tag"(%left) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %46 = "arith.constant"() {value = 65535 : i32} : () -> i32 
                    %47 = "arith.cmpi"(%45, %46) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %86 = "eco.case"(%47) ({
                          %48 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                          %49 = "eco.get_tag"(%48) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %50 = "arith.constant"() {value = 0 : i32} : () -> i32 
                          %51 = "arith.cmpi"(%49, %50) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %84 = "eco.case"(%51) ({
                                %52 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                %53 = "eco.get_tag"(%52) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                                %54 = "arith.constant"() {value = 65535 : i32} : () -> i32 
                                %55 = "arith.cmpi"(%53, %54) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                                %82 = "eco.case"(%55) ({
                                      %56 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                      %57 = "eco.project.custom"(%56) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                      %58 = "eco.get_tag"(%57) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                                      %59 = "arith.constant"() {value = 0 : i32} : () -> i32 
                                      %60 = "arith.cmpi"(%58, %59) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                                      %80 = "eco.case"(%60) ({
                                            %61 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                            %63 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                                            %64 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                                            %65 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                            %66 = "eco.project.custom"(%65) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                            %68 = "eco.project.custom"(%65) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                                            %69 = "eco.project.custom"(%65) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                                            %70 = "eco.project.custom"(%65) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                            %71 = "eco.project.custom"(%65) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                                            %72 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                                            %73 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
                                            %74 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                            %75 = "eco.construct.custom"(%74, %68, %69, %70, %71) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                            %76 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                            %77 = "eco.construct.custom"(%76, %key, %value, %72, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                            %78 = "eco.construct.custom"(%73, %63, %64, %75, %77) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                            "eco.yield"(%78) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                      }, {
                                            %79 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                            "eco.yield"(%79) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                      }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                      "eco.yield"(%80) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %81 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%81) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                "eco.yield"(%82) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %83 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%83) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%84) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %85 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                          "eco.yield"(%85) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%86) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%87) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %88 = "eco.get_tag"(%left) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %89 = "arith.constant"() {value = 65535 : i32} : () -> i32 
              %90 = "arith.cmpi"(%88, %89) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %129 = "eco.case"(%90) ({
                    %91 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                    %92 = "eco.get_tag"(%91) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %93 = "arith.constant"() {value = 0 : i32} : () -> i32 
                    %94 = "arith.cmpi"(%92, %93) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %127 = "eco.case"(%94) ({
                          %95 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                          %96 = "eco.get_tag"(%95) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %97 = "arith.constant"() {value = 65535 : i32} : () -> i32 
                          %98 = "arith.cmpi"(%96, %97) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %125 = "eco.case"(%98) ({
                                %99 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                %100 = "eco.project.custom"(%99) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                %101 = "eco.get_tag"(%100) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                                %102 = "arith.constant"() {value = 0 : i32} : () -> i32 
                                %103 = "arith.cmpi"(%101, %102) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                                %123 = "eco.case"(%103) ({
                                      %104 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                      %106 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                                      %107 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                                      %108 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                      %109 = "eco.project.custom"(%108) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                                      %111 = "eco.project.custom"(%108) {_operand_types = [!eco.value], field_index = 1} : (!eco.value) -> i64 
                                      %112 = "eco.project.custom"(%108) {_operand_types = [!eco.value], field_index = 2} : (!eco.value) -> !eco.value 
                                      %113 = "eco.project.custom"(%108) {_operand_types = [!eco.value], field_index = 3} : (!eco.value) -> !eco.value 
                                      %114 = "eco.project.custom"(%108) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                                      %115 = "eco.project.custom"(%left) {_operand_types = [!eco.value], field_index = 4} : (!eco.value) -> !eco.value 
                                      %116 = "eco.constant.null_cons"() {tag = 0} : () -> !eco.value 
                                      %117 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                      %118 = "eco.construct.custom"(%117, %111, %112, %113, %114) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                      %119 = "eco.constant.null_cons"() {tag = 1} : () -> !eco.value 
                                      %120 = "eco.construct.custom"(%119, %key, %value, %115, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                      %121 = "eco.construct.custom"(%116, %106, %107, %118, %120) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%121) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %122 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%122) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                "eco.yield"(%123) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %124 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                                "eco.yield"(%124) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%125) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %126 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                          "eco.yield"(%126) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%127) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %128 = "eco.construct.custom"(%color, %key, %value, %left, %right) {_operand_types = [!eco.value, i64, !eco.value, !eco.value, !eco.value], constructor = "RBNode_elm_builtin", size = 5, slot_kinds = array<i8: 0, 1, 0, 0, 0>, tag = 65535} : (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> !eco.value 
                    "eco.yield"(%128) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%129) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%130) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "value", "value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64, !eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "Dict_balance_$_30", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_13: i64, %mono_inline_14: !eco.value):
        %131 = "eco.papCreate"() {_result_kind = 1 : i8, arity = 2, function = @_tail_mono_inline_11_54, num_captured = 0} : () -> !eco.value 
        %132 = "arith.constant"() {value = false} : () -> i1 
        %133 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %134, %135, %136, %137 = "scf.while"(%mono_inline_13, %mono_inline_14, %132, %133) ({
            ^bb0(%138: i64, %139: !eco.value, %140: i1, %141: i64):
              %143 = "arith.constant"() {value = true} : () -> i1 
              %142 = "arith.xori"(%140, %143) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%142, %138, %139, %140, %141) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%144: i64, %145: !eco.value, %146: i1, %147: i64):
              %148 = "eco.get_tag"(%145) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %149 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %150 = "arith.cmpi"(%148, %149) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %159, %160, %161, %162 = "eco.case"(%150) ({
                    %151 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%144, %145, %151, %144) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %152 = "eco.project.list_head"(%145) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %153 = "eco.project.list_tail"(%145) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %155 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %156 = "eco.int.add"(%144, %155) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %157 = "arith.constant"() {value = false} : () -> i1 
                    %158 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%156, %153, %157, %158) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%159, %160, %161, %162) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%137) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:i:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "_tail_mono_inline_11_54", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%isGood: !eco.value, %x: i64, %xs: !eco.value):
        %163 = "eco.papExtend"(%isGood, %x) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @Stage2_makeLookup_$_1, _operand_types = [!eco.value, i64], _pap_prefix = 1, remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value 
        %164 = "eco.unbox"(%163) {_operand_types = [!eco.value]} : (!eco.value) -> i1 
        %166 = "eco.case"(%164) ({
              %165 = "eco.construct.list"(%x, %xs) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
              "eco.yield"(%165) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              "eco.yield"(%xs) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%166) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Stage2_lambda_5$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64, %xs: !eco.value):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %x, %xs) <{_operand_types = [!eco.value, i64, !eco.value], callee = @Stage2_lambda_5$cap}> : (!eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "Stage2_lambda_5$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @Stage2_main_$_0}> : () -> !eco.value 
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
  "eco.type_table"() {ctors = [[0, 0, 0, 1], [1, 2, 1, 0], [0, 3, 1, 0], [1, 4, 1, 0], [1, 5, 1, 0], [65535, 6, 1, 5], [0, 11, 6, 1]], fields = [[1, 2], [1, 4], [7, 0], [8, 2], [9, 5], [10, 5], [1, 5]], func_args = [], strings = ["Just", "field0", "Nothing", "Red", "Black", "RBEmpty_elm_builtin", "RBNode_elm_builtin", "field1", "field2", "field3", "field4", "Set_elm_builtin"], types = [[0, 0, 0], [1, 1, 0], [2, 0, 5], [3, 4, 0, 2], [4, 4, 2, 2], [5, 4, 4, 2], [6, 4, 6, 1]]} : () -> () 
} 
