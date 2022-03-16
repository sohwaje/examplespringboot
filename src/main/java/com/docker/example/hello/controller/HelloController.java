package com.docker.example.hello.controller;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class HelloController {

	private final Logger logger = LoggerFactory.getLogger(this.getClass());
	  
	@RequestMapping("/")
	public String hello() {
		logger.debug("테스트 로그 >>>>>>>>>>>>>>>>>>>");
		return "hello";
	}
}
