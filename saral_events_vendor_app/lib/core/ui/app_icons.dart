import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  // SVG strings for direct usage - no asset files needed
  static const String homeLineSvg = '''
<svg 
  xmlns="http://www.w3.org/2000/svg" 
  width="24" height="24" 
  viewBox="0 0 24 24" 
  fill="none" 
  stroke="currentColor" 
  stroke-width="1.8" 
  stroke-linecap="round" 
  stroke-linejoin="round"
  role="img" aria-label="Home"
>
  <path d="M12 3.4c-.3 0-.6.1-.9.3l-6.9 5.6c-.4.3-.7.8-.7 1.3v9c0 1 .8 1.8 1.8 1.8h4.8c.5 0 .9-.4.9-.9v-4.8c0-.5.4-.9.9-.9h1.8c.5 0 .9.4.9.9v4.8c0 .5.4.9.9.9h4.8c1 0 1.8-.8 1.8-1.8v-9c0-.5-.3-1-.7-1.3l-6.9-5.6c-.3-.2-.6-.3-.9-.3z"/>
</svg>''';

  static const String homeSolidSvg = '''
<svg 
  xmlns="http://www.w3.org/2000/svg" 
  width="24" height="24" 
  viewBox="0 0 24 24" 
  fill="currentColor" 
  role="img" aria-label="Home"
>
  <path d="M12 3.4c-.3 0-.6.1-.9.3L4.2 9.3c-.4.3-.7.8-.7 1.3v9c0 1 .8 1.8 1.8 1.8h4.8c.5 0 .9-.4.9-.9v-4.8c0-.5.4-.9.9-.9h1.8c.5 0 .9.4.9.9v4.8c0 .5.4.9.9.9h4.8c1 0 1.8-.8 1.8-1.8v-9c0-.5-.3-1-.7-1.3l-6.9-5.6c-.3-.2-.6-.3-.9-.3z"/>
</svg>''';

  static const String bellSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_31268)">
<path d="M10.75 5.5C12.1307 5.5 13.25 4.38071 13.25 3C13.25 1.61929 12.1307 0.5 10.75 0.5C9.36929 0.5 8.25 1.61929 8.25 3C8.25 4.38071 9.36929 5.5 10.75 5.5Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.93264 8V9.53357C9.93264 9.92469 10.088 10.2998 10.3646 10.5764C10.6411 10.8529 11.1089 11.0083 11.5 11.0083H0.5C0.891124 11.0083 1.35888 10.8529 1.63545 10.5764C1.91201 10.2998 2.06739 9.92469 2.06739 9.53357L2.06738 5.93262C2.06738 4.88963 2.48171 3.88935 3.21922 3.15184C3.95673 2.41433 4.95701 2 6 2" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5 13.5H7" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_31268">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String plusSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 6v12M6 12h12" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>''';

  static const String searchSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M10.502 2C5.80753 2 2.00195 5.80558 2.00195 10.5C2.00195 15.1944 5.80753 19 10.502 19C12.4884 19 14.3169 18.3176 15.7637 17.176L20.5877 22C20.9783 22.3905 21.6114 22.3905 22.002 22C22.3925 21.6095 22.3925 20.9763 22.002 20.5858L17.1779 15.7618C18.3196 14.3149 19.002 12.4865 19.002 10.5C19.002 5.80558 15.1964 2 10.502 2ZM4.00195 10.5C4.00195 6.91015 6.9121 4 10.502 4C14.0918 4 17.002 6.91015 17.002 10.5C17.002 12.2952 16.2755 13.9188 15.0981 15.0962C13.9208 16.2736 12.2972 17 10.502 17C6.9121 17 4.00195 14.0899 4.00195 10.5Z" fill="black"/>
</svg>''';

  static const String filterSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_37061)">
<path d="M13.5 0.5H0.5L5.5 7.5V13.5L8.5 11.5V7.5L13.5 0.5Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_37061">
<rect width="14" height="14" fill="white"/>
</svg>''';

  static const String ordersLineSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M8.5 0.5H5.5C4.94772 0.5 4.5 0.947715 4.5 1.5V2C4.5 2.55228 4.94772 3 5.5 3H8.5C9.05228 3 9.5 2.55228 9.5 2V1.5C9.5 0.947715 9.05228 0.5 8.5 0.5Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.75 1.5H11.25C11.5152 1.5 11.7696 1.60536 11.9571 1.79289C12.1446 1.98043 12.25 2.23478 12.25 2.5V12.5C12.25 12.7652 12.1446 13.0196 11.9571 13.2071C11.7696 13.3946 11.5152 13.5 11.25 13.5H2.75C2.48478 13.5 2.23043 13.3946 2.04289 13.2071C1.85536 13.0196 1.75 12.7652 1.75 12.5V2.5C1.75 2.23478 1.85536 1.98043 2.04289 1.79289C2.23043 1.60536 2.48478 1.5 2.75 1.5H4.25" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5 9L6.5 10L9.5 6" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String ordersSolidSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M5.5 0C4.94772 0 4.5 0.447716 4.5 1V1.5C4.5 2.05229 4.94772 2.5 5.5 2.5H8.5C9.05229 2.5 9.5 2.05229 9.5 1.5V1C9.5 0.447715 9.05229 0 8.5 0H5.5ZM3.24997 1H2.75C1.92157 1 1.25 1.67157 1.25 2.5V12.5C1.25 13.3284 1.92157 14 2.75 14H11.25C12.0784 14 12.75 13.3284 12.75 12.5V2.5C12.75 1.67157 12.0784 1 11.25 1H10.75V1.5C10.75 2.74264 9.74261 3.75 8.49997 3.75H5.49997C4.25733 3.75 3.24997 2.74264 3.24997 1.5V1ZM9.95 5.9C10.2814 6.14853 10.3485 6.61863 10.1 6.95L7.1 10.95C6.86117 11.2684 6.41517 11.3448 6.08397 11.124L4.58397 10.124C4.23933 9.89427 4.1462 9.42862 4.37596 9.08397C4.60573 8.73933 5.07138 8.6462 5.41603 8.87596L6.32569 9.48241L8.9 6.05C9.14853 5.71863 9.61863 5.65147 9.95 5.9Z" fill="currentColor"/>
</svg>''';

  static const String chatLineSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_34401)">
<path d="M7.00195 7.25C6.86388 7.25 6.75195 7.13807 6.75195 7C6.75195 6.86193 6.86388 6.75 7.00195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M7.00195 7.25C7.14002 7.25 7.25195 7.13807 7.25195 7C7.25195 6.86193 7.14002 6.75 7.00195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.25195 7.25C4.11388 7.25 4.00195 7.13807 4.00195 7C4.00195 6.86193 4.11388 6.75 4.25195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.25195 7.25C4.39002 7.25 4.50195 7.13807 4.50195 7C4.50195 6.86193 4.39002 6.75 4.25195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.75195 7.25C9.61388 7.25 9.50195 7.13807 9.50195 7C9.50195 6.86193 9.61388 6.75 9.75195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.75195 7.25C9.89002 7.25 10.002 7.13807 10.002 7C10.002 6.86193 9.89002 6.75 9.75195 6.75" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M6.99815 0.560548C5.83333 0.560911 4.69041 0.877215 3.69113 1.47577C2.69186 2.07433 1.87365 2.93272 1.32365 3.95952C0.773648 4.98632 0.512458 6.14308 0.567896 7.30658C0.623333 8.47009 0.993323 9.59677 1.63846 10.5666L0.558594 13.4397L4.17465 12.7858C5.04539 13.2113 6.00093 13.4348 6.97006 13.4396C7.93919 13.4444 8.8969 13.2304 9.77181 12.8135C10.6467 12.3967 11.4163 11.7877 12.023 11.032C12.6298 10.2764 13.0583 9.3935 13.2763 8.44921C13.4944 7.50493 13.4966 6.5236 13.2826 5.57838C13.0686 4.63315 12.6441 3.74841 12.0406 2.99011C11.4371 2.2318 10.6702 1.6195 9.79714 1.19883C8.92406 0.778157 7.96729 0.559976 6.99815 0.560548Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_34401">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String chatSolidSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_2922)">
<path fill-rule="evenodd" clip-rule="evenodd" d="M6.99794 0.0463878C8.04439 0.0457933 9.07748 0.281389 10.0202 0.735616C10.963 1.18986 11.7911 1.85105 12.4427 2.66988C13.0944 3.48871 13.5528 4.44407 13.7839 5.46474C14.0149 6.48542 14.0126 7.54508 13.7771 8.56473C13.5416 9.58439 13.079 10.5377 12.4238 11.3537C11.7686 12.1697 10.9376 12.8272 9.99286 13.2774C9.04811 13.7275 8.01395 13.9586 6.96747 13.9534C5.97656 13.9485 4.9988 13.7319 4.09948 13.3188L0.6335 13.9455C0.456415 13.9775 0.275783 13.9119 0.160531 13.7737C0.045278 13.6355 0.013186 13.446 0.0765003 13.2776L1.07073 10.6324C0.460382 9.63611 0.110161 8.50074 0.0544209 7.3309C-0.00544202 6.07452 0.276597 4.82543 0.870497 3.71667C1.4644 2.60791 2.34792 1.681 3.42696 1.03467C4.50595 0.388357 5.74019 0.0468069 6.99794 0.0463878ZM5 6.99994C5 7.55222 4.55228 7.99994 4 7.99994C3.44772 7.99994 3 7.55222 3 6.99994C3 6.44766 3.44772 5.99994 4 5.99994C4.55228 5.99994 5 6.44766 5 6.99994ZM7 7.99994C7.55228 7.99994 8 7.55222 8 6.99994C8 6.44766 7.55228 5.99994 7 5.99994C6.44772 5.99994 6 6.44766 6 6.99994C6 7.55222 6.44772 7.99994 7 7.99994ZM10 7.99994C10.5523 7.99994 11 7.55222 11 6.99994C11 6.44766 10.5523 5.99994 10 5.99994C9.44772 5.99994 9 6.44766 9 6.99994C9 7.55222 9.44772 7.99994 10 7.99994Z" fill="currentColor"/>
</g>
<defs>
<clipPath id="clip0_1222_2922">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String catalogLineSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M1 3C1.27614 3 1.5 2.77614 1.5 2.5C1.5 2.22386 1.27614 2 1 2C0.723858 2 0.5 2.22386 0.5 2.5C0.5 2.77614 0.723858 3 1 3Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.5 2.5H13.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M1 7.5C1.27614 7.5 1.5 7.27614 1.5 7C1.5 6.72386 1.27614 6.5 1 6.5C0.723858 6.5 0.5 6.72386 0.5 7C0.5 7.27614 0.723858 7.5 1 7.5Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.5 7H13.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M1 12C1.27614 12 1.5 11.7761 1.5 11.5C1.5 11.2239 1.27614 11 1 11C0.723858 11 0.5 11.2239 0.5 11.5C0.5 11.7761 0.723858 12 1 12Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.5 11.5H13.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String catalogSolidSvg = '''
<svg width="24" height="24" viewBox="0 0 14 12" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M2 1.49951C2 2.0518 1.55228 2.49951 1 2.49951C0.447715 2.49951 0 2.0518 0 1.49951C0 0.947232 0.447715 0.499512 1 0.499512C1.55228 0.499512 2 0.947232 2 1.49951ZM1 7C1.55228 7 2 6.55228 2 6C2 5.44772 1.55228 5 1 5C0.447715 5 0 5.44772 0 6C0 6.55228 0.447715 7 1 7ZM1 11.5005C1.55228 11.5005 2 11.0528 2 10.5005C2 9.9482 1.55228 9.5005 1 9.5005C0.447715 9.5005 0 9.9482 0 10.5005C0 11.0528 0.447715 11.5005 1 11.5005ZM4.75 0.750002C4.33579 0.750002 4 1.08579 4 1.5C4 1.91421 4.33579 2.25 4.75 2.25H13.25C13.6642 2.25 14 1.91421 14 1.5C14 1.08579 13.6642 0.750002 13.25 0.750002H4.75ZM4 6C4 5.58579 4.33579 5.25 4.75 5.25H13.25C13.6642 5.25 14 5.58579 14 6C14 6.41421 13.6642 6.75 13.25 6.75H4.75C4.33579 6.75 4 6.41421 4 6ZM4.75 9.75C4.33579 9.75 4 10.0858 4 10.5C4 10.9142 4.33579 11.25 4.75 11.25H13.25C13.6642 11.25 14 10.9142 14 10.5C14 10.0858 13.6642 9.75 13.25 9.75H4.75Z" fill="currentColor"/>
</svg>''';

  static const String calendarSvg = '''
<svg width="24" height="24" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_36636)">
<path d="M1.5 2C1.23478 2 0.98043 2.10536 0.792893 2.29289C0.605357 2.48043 0.5 2.73478 0.5 3V12.5C0.5 12.7652 0.605357 13.0196 0.792893 13.2071C0.98043 13.3946 1.23478 13.5 1.5 13.5H12.5C12.7652 13.5 13.0196 13.3946 13.2071 13.2071C13.3946 13.0196 13.5 12.7652 13.5 12.5V3C13.5 2.73478 13.3946 2.48043 13.2071 2.29289C13.0196 2.10536 12.7652 2 12.5 2H10.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M0.5 5.5H13.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.5 0.5V3.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M10.5 0.5V3.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.5 2H8.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_36636">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String businessDetailsSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12.642 2.26611H1.358C0.88414 2.26611 0.5 2.65025 0.5 3.12411V10.8761C0.5 11.35 0.88414 11.7341 1.358 11.7341H12.642C13.1159 11.7341 13.5 11.35 13.5 10.8761V3.12411C13.5 2.65025 13.1159 2.26611 12.642 2.26611Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.35938 5.87939H11.3462" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M9.35938 7.84863H11.3462" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.5072 6.20769C3.5072 7.11388 4.24181 7.8485 5.148 7.8485C5.37709 7.8485 5.59521 7.80154 5.79327 7.71674C6.37866 7.46609 6.78879 6.88479 6.78879 6.20769C6.78879 5.3015 6.05419 4.56689 5.148 4.56689C4.24181 4.56689 3.5072 5.3015 3.5072 6.20769Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M2.65381 9.47328C2.91453 8.97738 3.28096 8.56753 3.71787 8.28314C4.15478 7.99874 4.64748 7.84937 5.1486 7.84937C5.64973 7.84937 6.14243 7.99874 6.57934 8.28314C7.01625 8.56753 7.38268 8.97738 7.6434 9.47328" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

  static const String documentsSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_36877)">
<path d="M8.5 3.5V2.5C8.5 2.23478 8.39464 1.98043 8.20711 1.79289C8.01957 1.60536 7.76522 1.5 7.5 1.5H6.5" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4 10.5H1.5C1.23478 10.5 0.98043 10.3946 0.792893 10.2071C0.605357 10.0196 0.5 9.76522 0.5 9.5V2.5C0.5 2.23478 0.605357 1.98043 0.792893 1.79289C0.98043 1.60536 1.23478 1.5 1.5 1.5H2.5" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M12.5 5.5H7.5C6.94772 5.5 6.5 5.94772 6.5 6.5V12.5C6.5 13.0523 6.94772 13.5 7.5 13.5H12.5C13.0523 13.5 13.5 13.0523 13.5 12.5V6.5C13.5 5.94772 13.0523 5.5 12.5 5.5Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M6.75 0.5H2.25L2.66 2.12C2.68498 2.22843 2.74611 2.32513 2.83335 2.39419C2.92059 2.46325 3.02873 2.50057 3.14 2.5H5.86C5.97127 2.50057 6.07941 2.46325 6.16665 2.39419C6.25389 2.32513 6.31502 2.22843 6.34 2.12L6.75 0.5Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M8.5 8.5H11.5" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M8.5 10.5H11.5" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_36877">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String settingsSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_36841)">
<path d="M5.23004 2.25L5.66004 1.14C5.73256 0.952064 5.86015 0.790411 6.02609 0.676212C6.19204 0.562014 6.3886 0.500595 6.59004 0.5H7.41004C7.61148 0.500595 7.80805 0.562014 7.97399 0.676212C8.13994 0.790411 8.26752 0.952064 8.34004 1.14L8.77004 2.25L10.23 3.09L11.41 2.91C11.6065 2.88333 11.8065 2.91567 11.9846 3.00292C12.1626 3.09017 12.3107 3.22838 12.41 3.4L12.81 4.1C12.9125 4.27435 12.9598 4.47568 12.9455 4.67742C12.9312 4.87916 12.8561 5.07183 12.73 5.23L12 6.16V7.84L12.75 8.77C12.8761 8.92817 12.9512 9.12084 12.9655 9.32258C12.9798 9.52432 12.9325 9.72565 12.83 9.9L12.43 10.6C12.3307 10.7716 12.1826 10.9098 12.0046 10.9971C11.8265 11.0843 11.6265 11.1167 11.43 11.09L10.25 10.91L8.79004 11.75L8.36004 12.86C8.28752 13.0479 8.15994 13.2096 7.99399 13.3238C7.82805 13.438 7.63148 13.4994 7.43004 13.5H6.59004C6.3886 13.4994 6.19204 13.438 6.02609 13.3238C5.86015 13.2096 5.73256 13.0479 5.66004 12.86L5.23004 11.75L3.77004 10.91L2.59004 11.09C2.39356 11.1167 2.19358 11.0843 2.01552 10.9971C1.83747 10.9098 1.68937 10.7716 1.59004 10.6L1.19004 9.9C1.08754 9.72565 1.04032 9.52432 1.0546 9.32258C1.06888 9.12084 1.144 8.92817 1.27004 8.77L2.00004 7.84V6.16L1.25004 5.23C1.124 5.07183 1.04888 4.87916 1.0346 4.67742C1.02032 4.47568 1.06754 4.27435 1.17004 4.1L1.57004 3.4C1.66937 3.22838 1.81747 3.09017 1.99552 3.00292C2.17358 2.91567 2.37356 2.88333 2.57004 2.91L3.75004 3.09L5.23004 2.25ZM5.00004 7C5.00004 7.39556 5.11734 7.78224 5.3371 8.11114C5.55687 8.44004 5.86922 8.69638 6.23467 8.84776C6.60013 8.99913 7.00226 9.03874 7.39022 8.96157C7.77818 8.8844 8.13455 8.69392 8.41426 8.41421C8.69396 8.13451 8.88444 7.77814 8.96161 7.39018C9.03878 7.00222 8.99918 6.60009 8.8478 6.23463C8.69643 5.86918 8.44008 5.55682 8.11118 5.33706C7.78228 5.1173 7.3956 5 7.00004 5C6.46961 5 5.9609 5.21071 5.58583 5.58579C5.21076 5.96086 5.00004 6.46957 5.00004 7Z" stroke="black" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_36841">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';

  static const String vendorSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 11C14.2091 11 16 9.20914 16 7C16 4.79086 14.2091 3 12 3C9.79086 3 8 4.79086 8 7C8 9.20914 9.79086 11 12 11Z" fill="currentColor"/>
<path d="M19.5815 16.479C19.8642 16.8074 20 17.2333 20 17.6666V19C20 20.1046 19.1046 21 18 21H6C4.89543 21 4 20.1046 4 19V17.6666C4 17.2333 4.13576 16.8074 4.41847 16.479C6.25235 14.3488 8.96866 13 12 13C15.0313 13 17.7477 14.3488 19.5815 16.479Z" fill="currentColor"/>
</svg>''';

  static const String vendorLineSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M16 7C16 9.20914 14.2091 11 12 11C9.79086 11 8 9.20914 8 7C8 4.79086 9.79086 3 12 3C14.2091 3 16 4.79086 16 7ZM14 7C14 8.10457 13.1046 9 12 9C10.8954 9 10 8.10457 10 7C10 5.89543 10.8954 5 12 5C13.1046 5 14 5.89543 14 7Z" fill="currentColor"/>
<path fill-rule="evenodd" clip-rule="evenodd" d="M20 17.1666C20 16.7333 19.8642 16.3074 19.5815 15.979C17.7477 13.8488 15.0313 12.5 12 12.5C8.96866 12.5 6.25235 13.8488 4.41847 15.979C4.13576 16.3074 4 16.7333 4 17.1666V19C4 20.1046 4.89543 21 6 21H18C19.1046 21 20 20.1046 20 19V17.1666ZM18 17.2083C16.5313 15.5445 14.3887 14.5 12 14.5C9.61132 14.5 7.46872 15.5445 6 17.2083V19H18V17.2083ZM6.00017 17.1622C6.00017 17.1622 6.00018 17.1622 6.00017 17.1623C6.00016 17.1624 6.00015 17.1625 6.00012 17.1627C6.00014 17.1625 6.00016 17.1623 6.00017 17.1622Z" fill="currentColor"/>
</svg>''';

  static const String trashSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<g clip-path="url(#clip0_1222_37750)">
<path d="M1 3.5H13" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M2.5 3.5H11.5V12.5C11.5 12.7652 11.3946 13.0196 11.2071 13.2071C11.0196 13.3946 10.7652 13.5 10.5 13.5H3.5C3.23478 13.5 2.98043 13.3946 2.79289 13.2071C2.60536 13.0196 2.5 12.7652 2.5 12.5V3.5Z" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M4.5 3.5V3C4.5 2.33696 4.76339 1.70107 5.23223 1.23223C5.70107 0.763392 6.33696 0.5 7 0.5C7.66304 0.5 8.29893 0.763392 8.76777 1.23223C9.23661 1.70107 9.5 2.33696 9.5 3V3.5" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5.5 6.50146V10.503" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M8.5 6.50146V10.503" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>
</g>
<defs>
<clipPath id="clip0_1222_37750">
<rect width="14" height="14" fill="white"/>
</clipPath>
</defs>
</svg>''';
}

class SvgIcon extends StatelessWidget {
  final String svgString;
  final double size;
  final Color? color;
  const SvgIcon(this.svgString, {super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color;
    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: resolved != null ? ColorFilter.mode(resolved, BlendMode.srcIn) : null,
    );
  }
}


