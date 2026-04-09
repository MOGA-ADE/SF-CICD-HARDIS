/**
 * @author Ahmed Belhouadjeb
 * @date Creation 07/08/2019
 * @description UTIL_LogGenerator - class contains generic methods for debug logs
 */
public with sharing class UTIL_LogGenerator {

    private static final String DELIMETER = '::';
    private static final LoggingLevel DEFAULT_LOGGING_LEVEL = LoggingLevel.INFO;
    private static final String DEFAULT_MESSAGE = 'Message';
    private static final String ENTER_MESSAGE = 'Enter method';
    private static final String ERROR_LINE = 'ERROR LINE';
    private static final String ERROR_MESSAGE = 'ERROR MESSAGE';
    private static final String ERROR_STACK_TRACE = 'ERROR STACK TRACE';
    private static final String ERROR_TYPE = 'ERROR TYPE';
    private static final String EXCEPTION_ENTER_MESSAGE = 'Exception has been catched';
    private static final String EXIT_MESSAGE = 'Exit method';
    private static final String OBJECT_MESSAGE = 'Object';
    private static final String PREFIX = '##### ';
    private static final String LIMITS_MESSAGE = 'LIMIT BLOCK';

    private String className;
    private String methodName;
    private Phase currentPhase;

    public UTIL_LogGenerator() {
    }

    /**
     * @author Ahmed Belhouadjeb
      * @date Creation 07/08/2019
     * @date Modification 07/07/2016
     * @description Phase - All possible phases of the logger instance.
     */
    private enum Phase {
        START_PHASE, END_PHASE, PROCESSING_PHASE
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method starts debug block.
     * @param className Name of the class which method is debugged.
     * @param methodName Name of the method which is debugged.
     * @return void
     */
    public void start(String className, String methodName) {
        start(className, methodName, true);
    }

    /**
     * @author Ahmed Belhouadjeb
      * @date Creation 07/08/2019
     * @description The method starts debug block.
     * @param className Name of the class which method is debugged.
     * @param methodName Name of the method which is debugged.
     * @param withLimits Flag to choose, if limits should be printed out.
     * @return void
     */
    public void start(String className, String methodName, Boolean withLimits) {
        this.className = className;
        this.methodName = methodName;
        this.currentPhase = Phase.START_PHASE;
        this.debug(this.createMessage(ENTER_MESSAGE));
        if (withLimits) this.limits();
        this.currentPhase = Phase.PROCESSING_PHASE;
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method ends debug block.
     * @return void
     */
    public void end() {
        end(true);
    }

    /**
     * @author Ahmed Belhouadjeb
      * @date Creation 07/08/2019
     * @description The method ends debug block.
     * @param withLimits Flag to choose, if limits should be printed out.
     * @return void
     */
    public void end(Boolean withLimits) {
        this.currentPhase = Phase.END_PHASE;
        if (withLimits) this.limits();
        this.debug(this.createMessage(EXIT_MESSAGE));
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method logs a debug message.
     * @param msg name of the class which method is debugged.
     * @return void
     */
    public void log(String msg) {
        this.debug(createMessage(msg));
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method logs a debug message and object with pretty option.
     * @param msg name of the class which method is debugged.
     * @param obj Object to debug.
     * @param pretty Flag for serialization option.
     * @return void
     */
    public void log(String msg, Object obj, Boolean pretty) {
        this.debug(createMessage(msg));
        this.log(obj, pretty);
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method logs a debug object with pretty option.
     * @param obj Object to debug.
     * @param pretty Flag for serialization option.
     * @return void
     */
    public void log(Object obj, Boolean pretty) {
        this.debug(createMessage(OBJECT_MESSAGE, pretty ? JSON.serializePretty(obj) : JSON.serialize(obj)));
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method wraps standard debug method.
     * @param level Level of the debug message.
     * @param message Debug message.
     * @return void
     */
    private void debug(LoggingLevel level, String message) {
        System.debug(level, message);
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method wraps standard debug method with default logging level.
     * @param message Debug message.
     * @return void
     */
    private void debug(String message) {
        this.debug(DEFAULT_LOGGING_LEVEL, message);
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method builds correct format of the debug message.
     * @param messageDescription Description of the debug message.
     * @param message Debug message.
     * @return String Debug message with the correct format.
     */
    private String createMessage(String messageDescription, String message) {
        String resultMessage = this.className + DELIMETER;
        resultMessage += this.methodName + DELIMETER;
        resultMessage += '[' + messageDescription + ']: ' + message;
        return resultMessage;
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method builds correct format of debug message with description set to the default value.
     * @param message Debug message.
     * @return String Debug message with the correct format.
     */
    private String createMessage(String message) {
        return this.createMessage(DEFAULT_MESSAGE, message);
    }

    /**
     * @author Ahmed Belhouadjeb
 	 * @date Creation 07/08/2019
     * @description The method logs Salesforce limitations .
     * @param void.
     * @return void.
     */
    public void limits() {
        this.debug(this.createMessage(LIMITS_MESSAGE + '-' + String.valueOf(this.currentPhase)));
        this.debug(createMessage('QueryRows', Limits.getQueryRows() + ' / ' + Limits.getLimitQueryRows()));
        this.debug(createMessage('DMLRows', Limits.getDMLRows() + ' / ' + Limits.getLimitDMLRows()));
        this.debug(createMessage('DMLStatements', Limits.getDMLStatements() + ' / ' + Limits.getLimitDMLStatements()));
        this.debug(createMessage('CpuTime', Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime()));
    }


}