// Copyright (c) 2021 Nicholas Corgan
// SPDX-License-Identifier: BSL-1.0

%{
#include "Stream.hpp"
#include "Utility.hpp"
%}

%include <attribute.i>
%include <std_pair.i>
%include <stdint.i>
%include <typemaps.i>

%apply double& OUTPUT { double& fullScale };

%typemap(csclassmodifiers) std::pair<SoapySDR::Java::ErrorCode, SoapySDR::Java::StreamResult> "internal class";
%template(StreamResultPairInternal) std::pair<SoapySDR::Java::ErrorCode, SoapySDR::Java::StreamResult>;

// 
// Use the Java enum for direction
//

%typemap(csconstruct, excode=SWIGEXCODE,directorconnect="\n    SwigDirectorConnect();") SoapySDR::Device %{: this($imcall, true) {
    $excode$directorconnect
    BuildInfo.ValidateABI();
}%}

%typemap(cstype) const int direction "Direction"
%typemap(csin,
         pre="int temp$csinput = (int)$csinput;")
         const int direction
         "temp$csinput"

%typemap(csimports) SoapySDR::Device "
using System;
using System.Collections.Generic;
using System.Linq;"

%typemap(csdisposing, methodname="Dispose", methodmodifiers="protected", parameters="bool disposing") SoapySDR::Device {
    lock(this) {
      if (swigCPtr.Handle != global::System.IntPtr.Zero) {
        if (swigCMemOwn) {
          swigCMemOwn = false;
          Unmake(this);
        }
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero);
      }
    }
  }

%typemap(csdisposing_derived, methodname="Dispose", methodmodifiers="protected", parameters="bool disposing") SoapySDR::Device {
    lock(this) {
      if (swigCPtr.Handle != global::System.IntPtr.Zero) {
        if (swigCMemOwn) {
          swigCMemOwn = false;
          Unmake(this);
        }
        swigCPtr = new global::System.Runtime.InteropServices.HandleRef(null, global::System.IntPtr.Zero);
      }
      base.Dispose(disposing);
    }
  }

// Don't wrap deprecated functions
%ignore SoapySDR::Device::listSampleRates;
%ignore SoapySDR::Device::listBandwidths;
%ignore SoapySDR::Device::setCommandTime;
%ignore SoapySDR::Device::writeRegister(const unsigned, const unsigned);
%ignore SoapySDR::Device::readRegister(const unsigned) const;

// Ignore stream-related functions, we're rewriting
%ignore SoapySDR::Device::setupStream;
%ignore SoapySDR::Device::closeStream;
%ignore SoapySDR::Device::getStreamMTU;
%ignore SoapySDR::Device::activateStream;
%ignore SoapySDR::Device::deactivateStream;
%ignore SoapySDR::Device::readStream;
%ignore SoapySDR::Device::writeStream;
%ignore SoapySDR::Device::readStreamStatus;
%ignore SoapySDR::Device::getNumDirectAccessBuffers;
%ignore SoapySDR::Device::getDirectAccessBufferAddrs;
%ignore SoapySDR::Device::acquireReadBuffer;
%ignore SoapySDR::Device::releaseReadBuffer;
%ignore SoapySDR::Device::acquireWriteBuffer;
%ignore SoapySDR::Device::releaseWriteBuffer;

// Ignore functions explicitly using std::vector<unsigned> due to size_t workaround
%ignore SoapySDR::Device::writeRegisters;
%ignore SoapySDR::Device::readRegisters;

// Don't wrap development-layer functions
%ignore SoapySDR::Device::getNativeDeviceHandle;

// Per Java convention, convert trivial getters and setters to properties
%attributestring(SoapySDR::Device, std::string, DriverKey, getDriverKey);
%attributestring(SoapySDR::Device, std::string, HardwareKey, getHardwareKey);
%attributeval(SoapySDR::Device, SoapySDR::Kwargs, HardwareInfo, getHardwareInfo);
%attribute(SoapySDR::Device, double, MasterClockRate, getMasterClockRate, setMasterClockRate);
%attributeval(SoapySDR::Device, std::vector<SoapySDR::Range>, MasterClockRates, getMasterClockRates);
%attribute(SoapySDR::Device, double, ReferenceClockRate, getReferenceClockRate, setReferenceClockRate);
%attributeval(SoapySDR::Device, std::vector<SoapySDR::Range>, ReferenceClockRates, getReferenceClockRates);
%attributestring(SoapySDR::Device, std::string, ClockSource, getClockSource, setClockSource);
%attributeval(SoapySDR::Device, std::vector<std::string>, ClockSources, listClockSources);
%attributestring(SoapySDR::Device, std::string, TimeSource, getTimeSource, setTimeSource);
%attributeval(SoapySDR::Device, std::vector<std::string>, TimeSources, listTimeSources);
%attributeval(SoapySDR::Device, std::vector<std::string>, RegisterInterfaces, listRegisterInterfaces);
%attributeval(SoapySDR::Device, std::vector<std::string>, GPIOBanks, listGPIOBanks);
%attributeval(SoapySDR::Device, std::vector<std::string>, UARTs, listUARTs);

%typemap(cscode) SoapySDR::Device
%{
    /// <summary>
    /// Enumerate a list of all available devices on the system.
    /// </summary>
    public static KwargsList Enumerate() => Enumerate("");

    public TxStream SetupTxStream(
        string format,
        uint[] channels,
        IDictionary<string, string> kwargs)
    {
        return new TxStream(this, format, channels, Utility.ToKwargs(kwargs));
    }

    public TxStream SetupTxStream(
        string format,
        uint[] channels,
        string args) => SetupTxStream(format, channels, Utility.StringToKwargs(args));

    public RxStream SetupRxStream(
        string format,
        uint[] channels,
        IDictionary<string, string> kwargs)
    {
        return new RxStream(this, format, channels, Utility.ToKwargs(kwargs));
    }

    public RxStream SetupRxStream(
        string format,
        uint[] channels,
        string args) => SetupRxStream(format, channels, Utility.StringToKwargs(args));

    /// <summary>
    /// Set the center frequency of the chain.
    ///  - For RX, this specifies the down-conversion frequency.
    ///  - For TX, this specifies the up-conversion frequency.
    ///
    /// When no args are provided, setFrequency() will tune the "RF"
    /// component as close as possible to the requested center frequency.
    /// Tuning inaccuracies will be compensated for with the "BB" component.
    ///
    /// The args can be used to augment the tuning algorithm.
    ///  - Use "OFFSET" to specify an "RF" tuning offset,
    ///    usually with the intention of moving the LO out of the passband.
    ///    The offset will be compensated for using the "BB" component.
    ///  - Use the name of a component for the key and a frequency in Hz
    ///    as the value (any format) to enforce a specific frequency.
    ///    The other components will be tuned with compensation
    ///    to achieve the specified overall frequency.
    ///  - Use the name of a component for the key and the value "IGNORE"
    ///    so that the tuning algorithm will avoid altering the component.
    ///  - Vendor specific implementations can also use the same args to augment
    ///    tuning in other ways such as specifying fractional vs integer N tuning.
    /// </summary>
    /// <param name="direction">The channel direction (RX or TX)</param>
    /// <param name="channel">An available channel on the device</param>
    /// <param name="frequency">The center frequency in Hz</param>
    /// <param name="args">Optional tuner arguments</param>
    public void SetFrequency(Direction direction, uint channel, double frequency, string args = "") =>
        SetFrequency(direction, channel, frequency, Utility.StringToKwargs(args));

    /// <summary>
    /// Tune the center frequency of the specified element.
    ///  - For RX, this specifies the down-conversion frequency.
    ///  - For TX, this specifies the up-conversion frequency.
    ///
    /// When no args are provided, setFrequency() will tune the "RF"
    /// component as close as possible to the requested center frequency.
    /// Tuning inaccuracies will be compensated for with the "BB" component.
    ///
    /// The args can be used to augment the tuning algorithm.
    ///  - Use "OFFSET" to specify an "RF" tuning offset,
    ///    usually with the intention of moving the LO out of the passband.
    ///    The offset will be compensated for using the "BB" component.
    ///  - Use the name of a component for the key and a frequency in Hz
    ///    as the value (any format) to enforce a specific frequency.
    ///    The other components will be tuned with compensation
    ///    to achieve the specified overall frequency.
    ///  - Use the name of a component for the key and the value "IGNORE"
    ///    so that the tuning algorithm will avoid altering the component.
    ///  - Vendor specific implementations can also use the same args to augment
    ///    tuning in other ways such as specifying fractional vs integer N tuning.
    /// </summary>
    /// <param name="direction">The channel direction (RX or TX)</param>
    /// <param name="channel">An available channel on the device</param>
    /// <param name="name">The name of a tunable element</param>
    /// <param name="frequency">The center frequency in Hz</param>
    /// <param name="args">Optional tuner arguments</param>
    public void SetFrequency(Direction direction, uint channel, string name, double frequency, string args = "") =>
        SetFrequency(direction, channel, name, frequency, Utility.StringToKwargs(args));

    public T ReadSensor<T>(string key)
    {
        return (T)(new SoapyConvertible(ReadSensor(key)).ToType(typeof(T), null));
    }

    public T ReadSensor<T>(Direction direction, uint channel, string key)
    {
        return (T)(new SoapyConvertible(ReadSensor(direction, channel, key)).ToType(typeof(T), null));
    }

    public T ReadSetting<T>(string key)
    {
        return (T)(new SoapyConvertible(ReadSetting(key)).ToType(typeof(T), null));
    }

    public T ReadSetting<T>(Direction direction, uint channel, string key)
    {
        return (T)(new SoapyConvertible(ReadSetting(direction, channel, key)).ToType(typeof(T), null));
    }

    public void WriteSetting<T>(string key, T value)
    {
        WriteSetting(key, new SoapyConvertible(value).ToString());
    }

    public void WriteSetting<T>(Direction direction, uint channel, string key, T value)
    {
        WriteSetting(direction, channel, key, new SoapyConvertible(value).ToString());
    }

    //
    // Object overrides
    //

    public override string ToString() => string.Format("{0}:{1}", DriverKey, HardwareKey);

    public override bool Equals(object obj) => (obj as Device)?.swigCPtr.Equals(swigCPtr) ?? false;

    public override int GetHashCode() => GetType().GetHashCode() ^ (swigCPtr.GetHashCode() << 1);
%}

%nodefaultctor SoapySDR::Device;
%ignore SoapySDR::Device::make;
%ignore SoapySDR::Device::unmake(const std::vector<Device *> &);
%csmethodmodifiers SoapySDR::Device::unmake "private";
%csmethodmodifiers SoapySDR::Device::Pointer "private";

%feature("compactdefaultargs", "0") setHardwareTime;
%feature("compactdefaultargs", "0") readUART;

%include <SoapySDR/Device.hpp>

%csmethodmodifiers SoapySDR::Device::SetupStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::CloseStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::GetStreamMTUInternal "internal";
%csmethodmodifiers SoapySDR::Device::ActivateStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::DeactivateStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::ReadStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::WriteStreamInternal "internal";
%csmethodmodifiers SoapySDR::Device::ReadStreamStatusInternal "internal";

// Internal bridge functions to make the Java part easier
%extend SoapySDR::Device
{
    Device()
    {
        return SoapySDR::Device::make("");
    }

    Device(const SoapySDR::Kwargs &kwargs)
    {
        return SoapySDR::Device::make(kwargs);
    }

    Device(const std::string &args)
    {
        return SoapySDR::Device::make(args);
    }

    SoapySDR::Java::StreamHandle SetupStreamInternal(
        const SoapySDR::Java::Direction direction,
        const std::string& format,
        const SWIGSizeVector& channels,
        const SoapySDR::Kwargs& kwargs)
    {
        SoapySDR::Java::StreamHandle streamHandle;
        streamHandle.stream = self->setupStream(int(direction), format, copyVector<size_t>(channels), kwargs);
        streamHandle.format = format;
        streamHandle.channels = channels;

        return streamHandle;
    }

    void CloseStreamInternal(const SoapySDR::Java::StreamHandle& streamHandle)
    {
        self->closeStream(streamHandle.stream);
    }

    size_t GetStreamMTUInternal(const SoapySDR::Java::StreamHandle& streamHandle)
    {
        return self->getStreamMTU(streamHandle.stream);
    }

    SoapySDR::Java::ErrorCode ActivateStreamInternal(
        const SoapySDR::Java::StreamHandle& streamHandle,
        const SoapySDR::Java::StreamFlags flags,
        const long long timeNs,
        const size_t numElems)
    {
        return SoapySDR::Java::ErrorCode(self->activateStream(
            streamHandle.stream,
            int(flags),
            timeNs,
            numElems));
    }

    SoapySDR::Java::ErrorCode DeactivateStreamInternal(
        const SoapySDR::Java::StreamHandle& streamHandle,
        const SoapySDR::Java::StreamFlags flags,
        const long long timeNs)
    {
        return SoapySDR::Java::ErrorCode(self->deactivateStream(
            streamHandle.stream,
            int(flags),
            timeNs));
    }

    SoapySDR::Java::StreamResultPairInternal ReadStreamInternal(
        const SoapySDR::Java::StreamHandle& streamHandle,
        const SWIGSizeVector& buffs,
        const size_t numElems,
        const long timeoutUs)
    {
        SoapySDR::Java::StreamResultPairInternal resultPair;
        auto& errorCode = resultPair.first;
        auto& result = resultPair.second;

        const auto buffPtrs = reinterpretCastVector<void>(buffs);
        int intFlags = 0;
        auto cppRet = self->readStream(
            streamHandle.stream,
            buffPtrs.data(),
            numElems,
            intFlags,
            result.TimeNs,
            result.TimeoutUs);
        result.Flags = SoapySDR::Java::StreamFlags(intFlags);

        if(cppRet >= 0) result.NumSamples = static_cast<size_t>(cppRet);
        else            errorCode = static_cast<SoapySDR::Java::ErrorCode>(cppRet);

        return resultPair;
    }

    SoapySDR::Java::StreamResultPairInternal WriteStreamInternal(
        const SoapySDR::Java::StreamHandle& streamHandle,
        const SWIGSizeVector& buffs,
        const size_t numElems,
        const SoapySDR::Java::StreamFlags flags,
        const long long timeNs,
        const long timeoutUs)
    {
        SoapySDR::Java::StreamResultPairInternal resultPair;
        auto& errorCode = resultPair.first;
        auto& result = resultPair.second;

        const auto buffPtrs = reinterpretCastVector<const void>(buffs);
        auto intFlags = int(flags);
        auto cppRet = self->writeStream(
            streamHandle.stream,
            buffPtrs.data(),
            numElems,
            intFlags,
            timeNs,
            timeoutUs);
        result.Flags = SoapySDR::Java::StreamFlags(intFlags);

        if(cppRet >= 0) result.NumSamples = static_cast<size_t>(cppRet);
        else            errorCode = static_cast<SoapySDR::Java::ErrorCode>(cppRet);

        return resultPair;
    }

    SoapySDR::Java::StreamResultPairInternal ReadStreamStatusInternal(
        const SoapySDR::Java::StreamHandle& streamHandle,
        const long timeoutUs)
    {
        SoapySDR::Java::StreamResultPairInternal resultPair;
        auto& errorCode = resultPair.first;
        auto& result = resultPair.second;

        int intFlags = 0;
        errorCode = SoapySDR::Java::ErrorCode(self->readStreamStatus(
            streamHandle.stream,
            result.ChanMask,
            intFlags,
            result.TimeNs,
            result.TimeoutUs));
        result.Flags = SoapySDR::Java::StreamFlags(intFlags);

        return resultPair;
    }

    void WriteRegisters(
        const std::string &name,
        const unsigned addr,
        const SWIGSizeVector &value)
    {
        self->writeRegisters(name, addr, copyVector<unsigned>(value));
    }

    SWIGSizeVector ReadRegisters(
        const std::string &name,
        const unsigned addr,
        const size_t length) const
    {
        return copyVector<SWIGSize>(self->readRegisters(name, addr, length));
    }
};