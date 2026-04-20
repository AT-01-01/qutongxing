package com.example.qutongxing.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Component
public class RateLimitInterceptor implements HandlerInterceptor {

    private static final int MAX_REQUESTS_PER_MINUTE = 100;
    private static final int MAX_REQUESTS_PER_SECOND = 20;

    private final Map<String, RateLimitInfo> ipRequestCounts = new ConcurrentHashMap<>();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String clientIp = getClientIp(request);
        String key = clientIp + ":" + getCurrentMinute();

        RateLimitInfo info = ipRequestCounts.computeIfAbsent(key, k -> new RateLimitInfo());

        long currentSecond = System.currentTimeMillis() / 1000;

        if (info.minute != getCurrentMinute()) {
            info.minute = getCurrentMinute();
            info.minuteCount.set(0);
            info.secondCounts.clear();
        }

        if (info.secondCounts.containsKey(currentSecond)) {
            if (info.secondCounts.get(currentSecond).get() >= MAX_REQUESTS_PER_SECOND) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"success\":false,\"message\":\"请求过于频繁，请稍后再试\"}");
                return false;
            }
            info.secondCounts.get(currentSecond).incrementAndGet();
        } else {
            info.secondCounts.put(currentSecond, new AtomicInteger(1));
        }

        if (info.minuteCount.incrementAndGet() > MAX_REQUESTS_PER_MINUTE) {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"message\":\"请求过于频繁，请稍后再试\"}");
            return false;
        }

        return true;
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
    }

    private long getCurrentMinute() {
        return System.currentTimeMillis() / 60000;
    }

    private static class RateLimitInfo {
        long minute;
        AtomicInteger minuteCount = new AtomicInteger(0);
        Map<Long, AtomicInteger> secondCounts = new ConcurrentHashMap<>();
    }
}