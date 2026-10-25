module {
  "func.func"() ({
        %4 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %5 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %6 = "eco.construct.custom"(%5) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %7 = "eco.construct.list"(%6, %4) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %8 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %9 = "eco.construct.custom"(%8) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %10 = "eco.construct.list"(%9, %7) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %11 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %12 = "eco.construct.custom"(%11) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        %13 = "eco.construct.list"(%12, %10) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        %14 = "arith.constant"() {value = 3 : i32} : () -> i32 
        %0 = "bf.alloc"(%14) {_operand_types = [i32]} : (i32) -> !eco.value 
        %16 = "bf.cursor.init"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> !bf.cursor 
        %17 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %18 = "bf.write.u8"(%16, %17) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %19 = "arith.constant"() {value = 2 : i64} : () -> i64 
        %20 = "bf.write.u8"(%18, %19) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %21 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %22 = "bf.write.u8"(%20, %21) {_operand_types = [!bf.cursor, i64]} : (!bf.cursor, i64) -> !bf.cursor 
        %24 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %25 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %26 = "eco.construct.tuple2"(%24, %25) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        %27 = "eco.papCreate"() {arity = 1, function = @BytesLoopFusionRealOrderTest_lambda_0, num_captured = 0} : () -> !eco.value 
        %28 = "eco.call"(%26, %27) <{_operand_types = [!eco.value, !eco.value], callee = @Bytes_Decode_loop_$_8}> : (!eco.value, !eco.value) -> !eco.value 
        %29 = "bf.decoder.cursor.init"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> !bf.cursor 
        %30 = "arith.constant"() {value = 3 : i64} : () -> i64 
        %31 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %32 = "arith.maxsi"(%30, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %33 = "arith.constant"() {value = 2147483647 : i64} : () -> i64 
        %34 = "arith.cmpi"(%32, %33) {_operand_types = [i64, i64], predicate = 3 : i64} : (i64, i64) -> i1 
        %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %36 = "arith.muli"(%32, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %37 = "arith.trunci"(%36) {_operand_types = [i64]} : (i64) -> i32 
        %38 = "bf.require"(%29, %37) {_operand_types = [!bf.cursor, i32]} : (!bf.cursor, i32) -> i1 
        %39 = "arith.andi"(%34, %38) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
        %23 = "scf.if"(%39) ({
              %40 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
              %53, %54, %55 = "scf.while"(%32, %29, %40) ({
                  ^bb0(%41: i64, %42: !bf.cursor, %43: !eco.value):
                    %44 = "arith.cmpi"(%41, %31) {_operand_types = [i64, i64], predicate = 4 : i64} : (i64, i64) -> i1 
                    "scf.condition"(%44, %41, %42, %43) {_operand_types = [i1, i64, !bf.cursor, !eco.value]} : (i1, i64, !bf.cursor, !eco.value) -> () 
              }, {
                  ^bb0(%45: i64, %46: !bf.cursor, %47: !eco.value):
                    %48, %49 = "bf.read.u8"(%46) {_operand_types = [!bf.cursor]} : (!bf.cursor) -> (i64, !bf.cursor) 
                    %50 = "arith.constant"() {value = 1 : i64} : () -> i64 
                    %51 = "arith.subi"(%45, %50) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %52 = "eco.construct.list"(%48, %47) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
                    "scf.yield"(%51, %49, %52) {_operand_types = [i64, !bf.cursor, !eco.value]} : (i64, !bf.cursor, !eco.value) -> () 
              }) {_operand_types = [i64, !bf.cursor, !eco.value]} : (i64, !bf.cursor, !eco.value) -> (i64, !bf.cursor, !eco.value) 
              %56 = "eco.construct.custom"(%55) {_operand_types = [!eco.value], constructor = "Just", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
              "scf.yield"(%56) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %57 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
              "scf.yield"(%57) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) : (i1) -> !eco.value 
        %59 = "eco.get_tag"(%23) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
        %60 = "arith.constant"() {value = 0 : i32} : () -> i32 
        %61 = "arith.cmpi"(%59, %60) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
        %1 = "eco.case"(%61) ({
              %62 = "eco.project.custom"(%23) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %63 = "eco.string_literal"() {value = "["} : () -> !eco.value 
              %64 = "eco.string_literal"() {value = ","} : () -> !eco.value 
              %65 = "eco.papCreate"() {arity = 1, function = @String_fromInt_$_10, num_captured = 0} : () -> !eco.value 
              %67 = "eco.papCreate"(%65) {_fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value], arity = 3, function = @BytesLoopFusionRealOrderTest_lambda_20$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
              %68 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
              %73 = "arith.constant"() {value = 0 : i64} : () -> i64 
              %74 = "eco.call"(%67, %68, %73, %62) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_17}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
              %75 = "eco.call"(%64, %74) <{_operand_types = [!eco.value, !eco.value], callee = @String_join_$_12}> : (!eco.value, !eco.value) -> !eco.value 
              %76 = "eco.string_literal"() {value = "]"} : () -> !eco.value 
              %77 = "eco.string.append"(%75, %76) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
              %78 = "eco.string.append"(%63, %77) {_operand_types = [!eco.value, !eco.value]} : (!eco.value, !eco.value) -> !eco.value 
              "eco.yield"(%78) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %79 = "eco.string_literal"() {value = "Nothing"} : () -> !eco.value 
              "eco.yield"(%79) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        %81 = "eco.string_literal"() {value = "BytesLoopFusionRealOrderTest"} : () -> !eco.value 
        "eco.dbg"(%81, %1) {_operand_types = [!eco.value, !eco.value], arg_type_ids = array<i64: 1, 1>} : (!eco.value, !eco.value) -> () 
        %82 = "eco.call"(%1) <{_operand_types = [!eco.value], callee = @Elm_Kernel_VirtualDom_text, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%82) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.shadow_roots, function_type = () -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_main_$_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [i64], constructor = "U8", size = 1, slot_kinds = array<i8: 1>, tag = 3} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "Bytes_Encode_U8_$_1", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Done", size = 1, slot_kinds = array<i8: 0>, tag = 1} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Done_$_3", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Loop", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Loop_$_5", sym_visibility = "private"} : () -> () 
  "eco.global"() {sym_name = "__eco_caf$Bytes_Decode_unsignedInt8_$_6"} : () -> () 
  "func.func"() ({
        %0 = "eco.papCreate"() {arity = 2, function = @Elm_Kernel_Bytes_read_u8, num_captured = 0} : () -> !eco.value 
        %1 = "eco.construct.custom"(%0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.caf_memo, function_type = () -> (!eco.value), sym_name = "Bytes_Decode_unsignedInt8_$_6", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%state: !eco.value, %callback: !eco.value):
        %2 = "eco.papCreate"() {arity = 4, function = @Bytes_Decode_loopHelp_$_22, num_captured = 0} : () -> !eco.value 
        %3 = "eco.papExtend"(%2, %state, %callback) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, !eco.value, !eco.value], remaining_arity = 4, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value, !eco.value) -> !eco.value 
        %4 = "eco.construct.custom"(%3) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["tuple2:i:v", "value"], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Bytes_Decode_loop_$_8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v0: !eco.value, %bs: !eco.value):
        %2 = "eco.project.custom"(%_v0) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%2, %bs) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_Bytes_decode}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["custom:0:1:v", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "Bytes_Decode_decode_$_9", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64):
        %1 = "eco.string.from_int"(%arg0) {_operand_types = [i64]} : (i64) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64"], eco.logical_result_types = ["value"], function_type = (i64) -> (!eco.value), sym_name = "String_fromInt_$_10", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%sep: !eco.value, %chunks: !eco.value):
        %2 = "eco.call"(%chunks) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_toArray}> : (!eco.value) -> !eco.value 
        %3 = "eco.call"(%sep, %2) <{_operand_types = [!eco.value, !eco.value], callee = @Elm_Kernel_String_join}> : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%3) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), sym_name = "String_join_$_12", sym_visibility = "private"} : () -> () 
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
                    %12 = "eco.papExtend"(%fn, %7, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    "eco.yield"(%12) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }, {
                    %13 = "eco.project.list_head"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                    %14 = "eco.project.list_tail"(%8) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %15 = "eco.get_tag"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                    %16 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                    %17 = "arith.cmpi"(%15, %16) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                    %44 = "eco.case"(%17) ({
                          %18 = "eco.papExtend"(%fn, %13, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          %19 = "eco.papExtend"(%fn, %7, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                          "eco.yield"(%19) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }, {
                          %20 = "eco.project.list_head"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                          %21 = "eco.project.list_tail"(%14) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                          %22 = "eco.get_tag"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
                          %23 = "arith.constant"() {value = 65533 : i32} : () -> i32 
                          %24 = "arith.cmpi"(%22, %23) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
                          %43 = "eco.case"(%24) ({
                                %25 = "eco.papExtend"(%fn, %20, %acc) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %26 = "eco.papExtend"(%fn, %13, %25) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %27 = "eco.papExtend"(%fn, %7, %26) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%27) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }, {
                                %28 = "eco.project.list_head"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> i64 
                                %29 = "eco.project.list_tail"(%21) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                                %31 = "arith.constant"() {value = 500 : i64} : () -> i64 
                                %32 = "eco.int.gt"(%ctr, %31) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
                                %30 = "eco.case"(%32) ({
                                      %33 = "eco.call"(%29) <{_operand_types = [!eco.value], callee = @List_reverse_$_18}> : (!eco.value) -> !eco.value 
                                      %34 = "eco.call"(%fn, %acc, %33) <{_operand_types = [!eco.value, !eco.value, !eco.value], callee = @List_foldl_$_19}> : (!eco.value, !eco.value, !eco.value) -> !eco.value 
                                      "eco.yield"(%34) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }, {
                                      %35 = "arith.constant"() {value = 1 : i64} : () -> i64 
                                      %36 = "eco.int.add"(%ctr, %35) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                                      %37 = "eco.call"(%fn, %acc, %36, %29) <{_operand_types = [!eco.value, !eco.value, i64, !eco.value], callee = @List_foldrHelper_$_17}> : (!eco.value, !eco.value, i64, !eco.value) -> !eco.value 
                                      "eco.yield"(%37) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                                }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                                %39 = "eco.papExtend"(%fn, %28, %30) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %40 = "eco.papExtend"(%fn, %20, %39) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %41 = "eco.papExtend"(%fn, %13, %40) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                %42 = "eco.papExtend"(%fn, %7, %41) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                                "eco.yield"(%42) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                          }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                          "eco.yield"(%43) {_operand_types = [!eco.value]} : (!eco.value) -> () 
                    }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
                    "eco.yield"(%44) {_operand_types = [!eco.value]} : (!eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
              "eco.yield"(%45) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%46) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "i64", "cons:i:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, i64, !eco.value) -> (!eco.value), sym_name = "List_foldrHelper_$_17", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%list: !eco.value):
        %1 = "eco.call"(%list) <{_operand_types = [!eco.value], callee = @Elm_Kernel_List_reverse, eco.cse_safe}> : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "List_reverse_$_18", sym_visibility = "private"} : () -> () 
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
                    %28 = "eco.papExtend"(%17, %26, %18) {_call_kind = "singleton_fast", _capture_abi = [!eco.value], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_20$cap, _operand_types = [!eco.value, i64, !eco.value], remaining_arity = 2, slot_kinds = array<i8: 1, 0>} : (!eco.value, i64, !eco.value) -> !eco.value 
                    %29 = "arith.constant"() {value = false} : () -> i1 
                    %30 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%17, %28, %27, %29, %30) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
              "scf.yield"(%31, %32, %33, %34, %35) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i1, !eco.value) 
        "eco.return"(%9) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "cons:v:v", "cons:i:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_19", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.list"(%arg0, %arg1) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["i64", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "List_cons_$_20", sym_visibility = "private"} : () -> () 
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
  }) {eco.logical_param_types = ["value", "cons:i:v", "cons:i:v"], eco.logical_result_types = ["cons:i:v"], function_type = (!eco.value, !eco.value, !eco.value) -> (!eco.value), sym_name = "List_foldl_$_21", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%state: !eco.value, %callback: !eco.value, %bites: !eco.value, %offset: i64):
        %4 = "arith.constant"() {value = false} : () -> i1 
        %5 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        %6, %7, %8, %9, %10, %11 = "scf.while"(%state, %callback, %bites, %offset, %4, %5) ({
            ^bb0(%12: !eco.value, %13: !eco.value, %14: !eco.value, %15: i64, %16: i1, %17: !eco.value):
              %19 = "arith.constant"() {value = true} : () -> i1 
              %18 = "arith.xori"(%16, %19) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%18, %12, %13, %14, %15, %16, %17) {_operand_types = [i1, !eco.value, !eco.value, !eco.value, i64, i1, !eco.value]} : (i1, !eco.value, !eco.value, !eco.value, i64, i1, !eco.value) -> () 
        }, {
            ^bb0(%20: !eco.value, %21: !eco.value, %22: !eco.value, %23: i64, %24: i1, %25: !eco.value):
              %26 = "eco.papExtend"(%21, %20) {_call_kind = "singleton_fast", _capture_abi = [], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_0, _operand_types = [!eco.value, !eco.value], remaining_arity = 1, slot_kinds = array<i8: 0>} : (!eco.value, !eco.value) -> !eco.value 
              %28 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
              %29 = "eco.project.custom"(%26) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %30 = "eco.papExtend"(%29, %22, %23) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
              %32 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
              %34 = "eco.project.tuple2"(%30) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
              %36 = "eco.project.tuple2"(%30) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
              %37 = "eco.get_tag"(%36) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %38 = "arith.constant"() {value = 0 : i32} : () -> i32 
              %39 = "arith.cmpi"(%37, %38) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %46, %47, %48, %49, %50, %51 = "eco.case"(%39) ({
                    %40 = "eco.project.custom"(%36) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                    %41 = "arith.constant"() {value = false} : () -> i1 
                    %42 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
                    "eco.yield"(%40, %21, %22, %34, %41, %42) {_operand_types = [!eco.value, !eco.value, !eco.value, i64, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) -> () 
              }, {
                    %43 = "eco.project.custom"(%36) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
                    %44 = "eco.construct.tuple2"(%34, %43) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
                    %45 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%20, %21, %22, %23, %45, %44) {_operand_types = [!eco.value, !eco.value, !eco.value, i64, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) 
              "scf.yield"(%46, %47, %48, %49, %50, %51) {_operand_types = [!eco.value, !eco.value, !eco.value, i64, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) -> () 
        }) {_operand_types = [!eco.value, !eco.value, !eco.value, i64, i1, !eco.value]} : (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) -> (!eco.value, !eco.value, !eco.value, i64, i1, !eco.value) 
        "eco.return"(%11) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["tuple2:i:v", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "Bytes_Decode_loopHelp_$_22", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_23", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_24", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_25", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "eco.construct.custom"(%arg0) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "Bytes_Decode_Decoder_$_26", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%width: i64, %builders: !eco.value):
        %2 = "arith.constant"() {value = false} : () -> i1 
        %3 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %4, %5, %6, %7 = "scf.while"(%width, %builders, %2, %3) ({
            ^bb0(%8: i64, %9: !eco.value, %10: i1, %11: i64):
              %13 = "arith.constant"() {value = true} : () -> i1 
              %12 = "arith.xori"(%10, %13) {_operand_types = [i1, i1]} : (i1, i1) -> i1 
              "scf.condition"(%12, %8, %9, %10, %11) {_operand_types = [i1, i64, !eco.value, i1, i64]} : (i1, i64, !eco.value, i1, i64) -> () 
        }, {
            ^bb0(%14: i64, %15: !eco.value, %16: i1, %17: i64):
              %18 = "eco.get_tag"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> i32 
              %19 = "arith.constant"() {value = 65533 : i32} : () -> i32 
              %20 = "arith.cmpi"(%18, %19) {_operand_types = [i32, i32], predicate = 0 : i64} : (i32, i32) -> i1 
              %28, %29, %30, %31 = "eco.case"(%20) ({
                    %21 = "arith.constant"() {value = true} : () -> i1 
                    "eco.yield"(%14, %15, %21, %14) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }, {
                    %22 = "eco.project.list_head"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %23 = "eco.project.list_tail"(%15) {_operand_types = [!eco.value]} : (!eco.value) -> !eco.value 
                    %24 = "eco.call"(%22) <{_operand_types = [!eco.value], callee = @Bytes_Encode_getWidth_$_29}> : (!eco.value) -> i64 
                    %25 = "eco.int.add"(%14, %24) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
                    %26 = "arith.constant"() {value = false} : () -> i1 
                    %27 = "arith.constant"() {value = 0 : i64} : () -> i64 
                    "eco.yield"(%25, %23, %26, %27) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
              }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> (i64, !eco.value, i1, i64) 
              "scf.yield"(%28, %29, %30, %31) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> () 
        }) {_operand_types = [i64, !eco.value, i1, i64]} : (i64, !eco.value, i1, i64) -> (i64, !eco.value, i1, i64) 
        "eco.return"(%7) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["i64", "cons:v:v"], eco.logical_result_types = ["i64"], function_type = (i64, !eco.value) -> (i64), sym_name = "Bytes_Encode_getWidths_$_27", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: i64, %arg1: !eco.value):
        %2 = "eco.construct.custom"(%arg0, %arg1) {_operand_types = [i64, !eco.value], constructor = "Seq", size = 2, slot_kinds = array<i8: 1, 0>, tag = 8} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = [], eco.logical_result_types = ["value"], function_type = (i64, !eco.value) -> (!eco.value), sym_name = "Bytes_Encode_Seq_$_28", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%builder: !eco.value):
        %15 = "eco.case"(%builder) ({
              %1 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%1) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %2 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%2) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %3 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%3) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %4 = "arith.constant"() {value = 1 : i64} : () -> i64 
              "eco.yield"(%4) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %5 = "arith.constant"() {value = 2 : i64} : () -> i64 
              "eco.yield"(%5) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %6 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%6) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %7 = "arith.constant"() {value = 4 : i64} : () -> i64 
              "eco.yield"(%7) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %8 = "arith.constant"() {value = 8 : i64} : () -> i64 
              "eco.yield"(%8) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %10 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%10) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %12 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> i64 
              "eco.yield"(%12) {_operand_types = [i64]} : (i64) -> () 
        }, {
              %13 = "eco.project.custom"(%builder) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %14 = "eco.call"(%13) <{_operand_types = [!eco.value], callee = @Elm_Kernel_Bytes_width, eco.cse_safe}> : (!eco.value) -> i64 
              "eco.yield"(%14) {_operand_types = [i64]} : (i64) -> () 
        }) {_operand_types = [!eco.value], case_kind = "ctor", tags = array<i64: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10>} : (!eco.value) -> i64 
        "eco.return"(%15) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), sym_name = "Bytes_Encode_getWidth_$_29", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_8: !eco.value, %x: i64, %acc: !eco.value):
        %70 = "eco.papExtend"(%mono_inline_8, %x) {_call_kind = "direct_known_segmentation", _operand_types = [!eco.value, i64], remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value 
        %71 = "eco.construct.list"(%70, %acc) {_operand_types = [!eco.value, !eco.value], head_kind = 0, head_unboxed = false} : (!eco.value, !eco.value) -> !eco.value 
        "eco.return"(%71) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_20$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64, %acc: !eco.value):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %x, %acc) <{_operand_types = [!eco.value, i64, !eco.value], callee = @BytesLoopFusionRealOrderTest_lambda_20$cap}> : (!eco.value, i64, !eco.value) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64", "cons:v:v"], eco.logical_result_types = ["cons:v:v"], function_type = (!eco.value, i64, !eco.value) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_20$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%_v2: !eco.value):
        %25 = "eco.project.tuple2"(%_v2) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %27 = "eco.project.tuple2"(%_v2) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> !eco.value 
        %28 = "arith.constant"() {value = 0 : i64} : () -> i64 
        %29 = "eco.int.le"(%25, %28) {_operand_types = [i64, i64]} : (i64, i64) -> i1 
        %41 = "eco.case"(%29) ({
              %30 = "eco.construct.custom"(%27) {_operand_types = [!eco.value], constructor = "Done", size = 1, slot_kinds = array<i8: 0>, tag = 1} : (!eco.value) -> !eco.value 
              %32 = "eco.papCreate"(%30) {_fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_18$cap, _operand_types = [!eco.value], arity = 3, function = @BytesLoopFusionRealOrderTest_lambda_18$clo, num_captured = 1, slot_kinds = array<i8: 0>} : (!eco.value) -> !eco.value 
              %33 = "eco.construct.custom"(%32) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
              "eco.yield"(%33) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }, {
              %34 = "eco.papCreate"(%27, %25) {_fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_1$cap, _operand_types = [!eco.value, i64], arity = 3, function = @BytesLoopFusionRealOrderTest_lambda_1$clo, num_captured = 2, slot_kinds = array<i8: 0, 1>} : (!eco.value, i64) -> !eco.value 
              %35 = "eco.call"() <{callee = @Bytes_Decode_unsignedInt8_$_6}> : () -> !eco.value 
              %38 = "eco.project.custom"(%35) {_operand_types = [!eco.value], field_index = 0} : (!eco.value) -> !eco.value 
              %39 = "eco.papCreate"(%38, %34) {_fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_19$cap, _operand_types = [!eco.value, !eco.value], arity = 4, function = @BytesLoopFusionRealOrderTest_lambda_19$clo, num_captured = 2, slot_kinds = array<i8: 0, 0>} : (!eco.value, !eco.value) -> !eco.value 
              %40 = "eco.construct.custom"(%39) {_operand_types = [!eco.value], constructor = "Decoder", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
              "eco.yield"(%40) {_operand_types = [!eco.value]} : (!eco.value) -> () 
        }) {_operand_types = [i1], case_kind = "bool", tags = array<i64: 1, 0>} : (i1) -> !eco.value 
        "eco.return"(%41) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["tuple2:i:v"], eco.logical_result_types = ["custom:0:1:v"], function_type = (!eco.value) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_0", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_7: !eco.value, %mono_inline_2: !eco.value, %bites: !eco.value, %offset: i64):
        %42 = "eco.papExtend"(%mono_inline_7, %bites, %offset) {_call_kind = "segmentation_unknown", _operand_types = [!eco.value, !eco.value, i64], slot_kinds = array<i8: 0, 1>} : (!eco.value, !eco.value, i64) -> !eco.value 
        %45 = "eco.project.tuple2"(%42) {_operand_types = [!eco.value], field = 0} : (!eco.value) -> i64 
        %47 = "eco.project.tuple2"(%42) {_operand_types = [!eco.value], field = 1} : (!eco.value) -> i64 
        %48 = "eco.papExtend"(%mono_inline_2, %47) {_call_kind = "singleton_fast", _capture_abi = [!eco.value, i64], _fast_evaluator = @BytesLoopFusionRealOrderTest_lambda_1$cap, _operand_types = [!eco.value, i64], remaining_arity = 1, slot_kinds = array<i8: 1>} : (!eco.value, i64) -> !eco.value 
        %49 = "eco.construct.tuple2"(%45, %48) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%49) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_19$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %bites: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.project.closure"(%closure) {index = 1, is_unboxed = false} : (!eco.value) -> !eco.value 
        %5 = "eco.call"(%3, %4, %bites, %offset) <{_operand_types = [!eco.value, !eco.value, !eco.value, i64], callee = @BytesLoopFusionRealOrderTest_lambda_19$cap}> : (!eco.value, !eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%5) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_19$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%acc: !eco.value, %n: i64, %x: i64):
        %36 = "arith.constant"() {value = 1 : i64} : () -> i64 
        %37 = "eco.int.sub"(%n, %36) {_operand_types = [i64, i64]} : (i64, i64) -> i64 
        %38 = "eco.construct.list"(%x, %acc) {_operand_types = [i64, !eco.value], head_kind = 1, head_unboxed = true} : (i64, !eco.value) -> !eco.value 
        %39 = "eco.construct.tuple2"(%37, %38) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        %40 = "eco.construct.custom"(%39) {_operand_types = [!eco.value], constructor = "Loop", size = 1, slot_kinds = array<i8: 0>, tag = 0} : (!eco.value) -> !eco.value 
        "eco.return"(%40) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["cons:i:v", "i64", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_1$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %x: i64):
        %2 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %3 = "eco.project.closure"(%closure) {index = 1, is_unboxed = true} : (!eco.value) -> i64 
        %4 = "eco.call"(%2, %3, %x) <{_operand_types = [!eco.value, i64, i64], callee = @BytesLoopFusionRealOrderTest_lambda_1$cap}> : (!eco.value, i64, i64) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_1$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%mono_inline_1: !eco.value, %_v0: !eco.value, %offset: i64):
        %31 = "eco.construct.tuple2"(%offset, %mono_inline_1) {_operand_types = [i64, !eco.value], unboxed_bitmap = 1} : (i64, !eco.value) -> !eco.value 
        "eco.return"(%31) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_18$cap", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%closure: !eco.value, %_v0: !eco.value, %offset: i64):
        %3 = "eco.project.closure"(%closure) {index = 0, is_unboxed = false} : (!eco.value) -> !eco.value 
        %4 = "eco.call"(%3, %_v0, %offset) <{_operand_types = [!eco.value, !eco.value, i64], callee = @BytesLoopFusionRealOrderTest_lambda_18$cap}> : (!eco.value, !eco.value, i64) -> !eco.value 
        "eco.return"(%4) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value", "i64"], eco.logical_result_types = ["tuple2:i:v"], function_type = (!eco.value, !eco.value, i64) -> (!eco.value), sym_name = "BytesLoopFusionRealOrderTest_lambda_18$clo", sym_visibility = "private"} : () -> () 
  "func.func"() ({
        %0 = "eco.call"() <{callee = @BytesLoopFusionRealOrderTest_main_$_0}> : () -> !eco.value 
        "eco.return"(%0) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.list_chunks, function_type = () -> (!eco.value), sym_name = "main", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: !eco.value):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "value"], eco.logical_result_types = ["value"], function_type = (!eco.value, !eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_decode", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value, %arg1: i64):
        %2 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%2) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value", "i64"], eco.logical_result_types = ["value"], function_type = (!eco.value, i64) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_Bytes_read_u8", sym_visibility = "private"} : () -> () 
  "func.func"() ({
      ^bb0(%arg0: !eco.value):
        %1 = "arith.constant"() {value = 0 : i64} : () -> i64 
        "eco.return"(%1) {_operand_types = [i64]} : (i64) -> () 
  }) {eco.gc_leaf, eco.logical_param_types = ["value"], eco.logical_result_types = ["i64"], function_type = (!eco.value) -> (i64), is_kernel = true, sym_name = "Elm_Kernel_Bytes_width", sym_visibility = "private"} : () -> () 
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
      ^bb0(%arg0: !eco.value):
        %1 = "eco.constant"() {kind = 2 : i32} : () -> !eco.value 
        "eco.return"(%1) {_operand_types = [!eco.value]} : (!eco.value) -> () 
  }) {eco.logical_param_types = ["value"], eco.logical_result_types = ["value"], function_type = (!eco.value) -> (!eco.value), is_kernel = true, sym_name = "Elm_Kernel_VirtualDom_text", sym_visibility = "private"} : () -> () 
  "eco.type_table"() {ctors = [[0, 0, 0, 0], [0, 1, 0, 1], [1, 3, 1, 2], [2, 5, 3, 2], [3, 6, 5, 1], [4, 7, 6, 2], [5, 8, 8, 2], [6, 9, 10, 2], [7, 10, 12, 2], [8, 11, 14, 2], [9, 12, 16, 2], [10, 0, 18, 1], [0, 13, 21, 1], [1, 14, 22, 1], [0, 15, 23, 1], [0, 15, 26, 1], [0, 15, 29, 1]], fields = [[2, 4], [2, 3], [4, 4], [2, 3], [4, 4], [2, 4], [2, 3], [4, 4], [2, 3], [4, 4], [2, 3], [4, 2], [2, 3], [4, 2], [2, 4], [4, 6], [2, 4], [4, 1], [2, 0], [0, 4], [0, 7], [2, 8], [2, 7], [2, 12], [0, 4], [0, 10], [2, 16], [0, 4], [0, 4], [2, 20]], func_args = [4, 0, 4, 0, 4, 0], strings = ["Bytes", "I8", "field0", "I16", "field1", "I32", "U8", "U16", "U32", "F32", "F64", "Seq", "Utf8", "Loop", "Done", "Decoder"], types = [[0, 4, 0, 1], [1, 0, 4], [2, 0, 1], [3, 4, 1, 0], [4, 0, 0], [5, 4, 1, 11], [6, 1, 5], [7, 1, 4], [8, 2, 2, 19, 2], [9, 1, 1], [10, 4, 12, 2], [11, 5, 0, 1, 8], [12, 5, 1, 1, 11], [13, 4, 14, 1], [14, 2, 2, 24, 2], [15, 5, 2, 1, 14], [16, 5, 3, 1, 15], [17, 4, 15, 1], [18, 2, 2, 27, 2], [19, 5, 4, 1, 18], [20, 5, 5, 1, 19], [21, 4, 16, 1]]} : () -> () 
} 
