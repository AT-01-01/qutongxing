package com.example.qutongxing.config;

import com.example.qutongxing.dto.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleValidationExceptions(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        Map<String, Object> details = baseDetails("参数验证失败", request);
        details.put("fieldErrors", errors);
        return ResponseEntity.badRequest().body(ApiResponse.error("参数验证失败", details));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException ex, HttpServletRequest request) {
        Map<String, Object> details = baseDetails("上传文件大小超过限制", request);
        details.put("maxSize", ex.getMaxUploadSize());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error("上传文件大小超过限制", details));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleDataIntegrityViolationException(DataIntegrityViolationException ex, HttpServletRequest request) {
        String rootMessage = extractRootMessage(ex);
        Map<String, Object> details = baseDetails("数据库写入失败", request);
        details.put("rootCause", rootMessage);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.error("数据库约束冲突，请检查输入数据", details));
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleRuntimeException(RuntimeException ex, HttpServletRequest request) {
        Map<String, Object> details = baseDetails(ex.getMessage(), request);
        details.put("exception", ex.getClass().getSimpleName());
        return ResponseEntity.badRequest().body(ApiResponse.error(ex.getMessage(), details));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Map<String, Object>>> handleException(Exception ex, HttpServletRequest request) {
        ex.printStackTrace();
        String rootMessage = extractRootMessage(ex);
        Map<String, Object> details = baseDetails("服务器内部错误", request);
        details.put("exception", ex.getClass().getSimpleName());
        details.put("rootCause", rootMessage);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiResponse.error("服务器内部错误", details));
    }

    private Map<String, Object> baseDetails(String message, HttpServletRequest request) {
        Map<String, Object> details = new HashMap<>();
        details.put("message", message);
        details.put("path", request.getRequestURI());
        details.put("method", request.getMethod());
        details.put("timestamp", LocalDateTime.now().toString());
        return details;
    }

    private String extractRootMessage(Throwable throwable) {
        Throwable root = throwable;
        while (root.getCause() != null) {
            root = root.getCause();
        }
        return root.getMessage();
    }
}